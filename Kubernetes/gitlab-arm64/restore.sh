#!/bin/bash
set -e

NAMESPACE="gitlab"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="${1:-}"

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: ./restore.sh <backup-directory>"
  echo ""
  echo "Available backups:"
  ls -d "$SCRIPT_DIR"/backups/*/ 2>/dev/null || echo "  (none found)"
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  # Try relative to backups/
  if [ -d "$SCRIPT_DIR/backups/$BACKUP_DIR" ]; then
    BACKUP_DIR="$SCRIPT_DIR/backups/$BACKUP_DIR"
  else
    echo "Error: Backup directory not found: $BACKUP_DIR"
    exit 1
  fi
fi

BACKUP_FILE=$(ls "$BACKUP_DIR" | grep '_gitlab_backup.tar' | head -1)
if [ -z "$BACKUP_FILE" ]; then
  echo "Error: No *_gitlab_backup.tar found in $BACKUP_DIR"
  exit 1
fi

echo "=== GitLab Restore ==="
echo "Backup dir:  $BACKUP_DIR"
echo "Backup file: $BACKUP_FILE"
echo ""

# --- Step 1: Restore local secrets for deploy.sh ---
if [ -d "$BACKUP_DIR/ssl" ]; then
  echo "Step 1a: Restoring SSL certificates..."
  mkdir -p "$SCRIPT_DIR/ssl"
  cp -r "$BACKUP_DIR/ssl/"* "$SCRIPT_DIR/ssl/"
fi

if [ -d "$BACKUP_DIR/secrets" ]; then
  echo "Step 1b: Restoring local secrets..."
  mkdir -p "$SCRIPT_DIR/secrets"
  cp -r "$BACKUP_DIR/secrets/"* "$SCRIPT_DIR/secrets/"
fi

# --- Step 2: Deploy GitLab (creates namespace, secrets, PVCs, pods) ---
echo ""
echo "Step 2: Deploying GitLab infrastructure..."
"$SCRIPT_DIR/deploy.sh"

# --- Step 3: Wait for GitLab pod to be running ---
echo ""
echo "Step 3: Waiting for GitLab pod to be running..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=gitlab -n "$NAMESPACE" --timeout=600s || {
  echo "Warning: Pod not ready after 10 minutes, continuing anyway..."
}

GITLAB_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=gitlab -o jsonpath='{.items[0].metadata.name}')
echo "GitLab pod: $GITLAB_POD"

# --- Step 4: Copy backup file into the pod ---
echo ""
echo "Step 4: Copying backup archive into pod..."
kubectl cp "$BACKUP_DIR/$BACKUP_FILE" "$NAMESPACE/$GITLAB_POD:/var/opt/gitlab/backups/$BACKUP_FILE"
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- chown git:git "/var/opt/gitlab/backups/$BACKUP_FILE"

# --- Step 5: Restore gitlab-secrets.json (CRITICAL) ---
echo ""
echo "Step 5: Restoring gitlab-secrets.json..."
kubectl cp "$BACKUP_DIR/gitlab-secrets.json" "$NAMESPACE/$GITLAB_POD:/etc/gitlab/gitlab-secrets.json"

# --- Step 6: Reconfigure GitLab to pick up secrets ---
echo ""
echo "Step 6: Reconfiguring GitLab..."
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-ctl reconfigure

# --- Step 7: Stop services that write to the DB ---
echo ""
echo "Step 7: Stopping puma and sidekiq for restore..."
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-ctl stop puma
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-ctl stop sidekiq

# Verify they are stopped
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-ctl status || true

# --- Step 8: Run the restore ---
# Extract the backup timestamp (everything before _gitlab_backup.tar)
BACKUP_TIMESTAMP="${BACKUP_FILE%_gitlab_backup.tar}"

echo ""
echo "Step 8: Restoring from backup $BACKUP_TIMESTAMP..."
echo "This may take several minutes."
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-backup restore BACKUP="$BACKUP_TIMESTAMP" force=yes

# --- Step 9: Restart GitLab ---
echo ""
echo "Step 9: Restarting GitLab..."
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-ctl restart

# --- Step 10: Run sanity check ---
echo ""
echo "Step 10: Running GitLab integrity check..."
kubectl exec -n "$NAMESPACE" "$GITLAB_POD" -- gitlab-rake gitlab:check SANITIZE=true || true

echo ""
echo "=== Restore Complete ==="
echo ""
echo "GitLab should now be running with the restored data."
echo "Access it at: https://gitlab.local"
echo ""
echo "If you see issues, check logs:"
echo "  kubectl logs -f deployment/gitlab -n $NAMESPACE"
