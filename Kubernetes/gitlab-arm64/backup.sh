#!/bin/bash
set -e

NAMESPACE="gitlab"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/$(date +%Y%m%d-%H%M%S)"

echo "=== GitLab Backup ==="

# --- Find GitLab pod ---
GITLAB_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=gitlab -o jsonpath='{.items[0].metadata.name}')
if [ -z "$GITLAB_POD" ]; then
  echo "Error: Could not find GitLab pod"
  exit 1
fi
echo "GitLab pod: $GITLAB_POD"

# --- Step 1: Run GitLab backup inside the container ---
echo ""
echo "Step 1: Creating GitLab application backup (repos, DB, uploads)..."
echo "This may take several minutes depending on data size."
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-backup create STRATEGY=copy

# --- Step 2: Find the backup tarball ---
echo ""
echo "Step 2: Finding backup archive..."
BACKUP_FILE=$(kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- ls -t /var/opt/gitlab/backups/ | grep '_gitlab_backup.tar' | head -1)
if [ -z "$BACKUP_FILE" ]; then
  echo "Error: No backup file found"
  exit 1
fi
echo "Backup file: $BACKUP_FILE"

# --- Step 3: Copy backup to local machine ---
mkdir -p "$BACKUP_DIR"
echo ""
echo "Step 3: Copying backup to $BACKUP_DIR ..."

echo "  - Application backup..."
kubectl cp "$NAMESPACE/$GITLAB_POD:/var/opt/gitlab/backups/$BACKUP_FILE" "$BACKUP_DIR/$BACKUP_FILE"

# --- Step 4: Copy GitLab secrets (critical for restore) ---
echo "  - GitLab secrets file (gitlab-secrets.json)..."
kubectl cp "$NAMESPACE/$GITLAB_POD:/etc/gitlab/gitlab-secrets.json" "$BACKUP_DIR/gitlab-secrets.json"

echo "  - GitLab config (gitlab.rb)..."
kubectl cp "$NAMESPACE/$GITLAB_POD:/etc/gitlab/gitlab.rb" "$BACKUP_DIR/gitlab.rb"

# --- Step 5: Copy K8s secrets ---
echo "  - Kubernetes TLS secret..."
kubectl get secret gitlab-tls -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/gitlab-tls-secret.yaml"

echo "  - Kubernetes root password secret..."
kubectl get secret gitlab-root-password -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/gitlab-root-password-secret.yaml"

# --- Step 6: Copy local certs/password ---
if [ -d "$SCRIPT_DIR/ssl" ]; then
  cp -r "$SCRIPT_DIR/ssl" "$BACKUP_DIR/ssl"
  echo "  - SSL certificates..."
fi
if [ -d "$SCRIPT_DIR/secrets" ]; then
  cp -r "$SCRIPT_DIR/secrets" "$BACKUP_DIR/secrets"
  echo "  - Local secrets..."
fi

echo ""
echo "=== Backup Complete ==="
echo "Location: $BACKUP_DIR"
echo ""
ls -lh "$BACKUP_DIR"
echo ""
echo "Files included:"
echo "  - $BACKUP_FILE        (repos, DB, uploads, CI artifacts)"
echo "  - gitlab-secrets.json          (encryption keys — CRITICAL)"
echo "  - gitlab.rb                    (GitLab configuration)"
echo "  - gitlab-tls-secret.yaml       (K8s TLS secret)"
echo "  - gitlab-root-password-secret.yaml (K8s root password)"
echo "  - ssl/                         (TLS cert & key)"
echo "  - secrets/                     (root password file)"
echo ""
echo "To transfer to another cluster:"
echo "  1. Copy this entire folder to the target machine"
echo "  2. Run: ./restore.sh $BACKUP_DIR"
