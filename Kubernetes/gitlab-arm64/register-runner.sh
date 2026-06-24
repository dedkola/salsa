#!/bin/bash
set -e

NAMESPACE="gitlab"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALUES_FILE="$SCRIPT_DIR/runner-values.yaml"

echo "=== GitLab Runner Setup (Helm) ==="
echo ""
echo "1. Go to https://gitlab.local/admin/runners"
echo "2. Click 'New instance runner'"
echo "3. Configure tags and options, click 'Create runner'"
echo "4. Copy the runner authentication token (glrt-...)"
echo ""
read -p "Paste the runner token: " RUNNER_TOKEN

if [ -z "$RUNNER_TOKEN" ]; then
  echo "Error: No token provided"
  exit 1
fi

# --- Prerequisites ---
if ! command -v helm &>/dev/null; then
  echo "Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add GitLab Helm repo
helm repo add gitlab https://charts.gitlab.io 2>/dev/null || true
helm repo update gitlab

# --- Get GitLab service ClusterIP for host_aliases ---
GITLAB_IP=$(kubectl get svc -n "$NAMESPACE" gitlab -o jsonpath='{.spec.clusterIP}')
if [ -z "$GITLAB_IP" ]; then
  echo "Error: Could not get ClusterIP of gitlab service"
  echo "Is GitLab deployed? Run ./deploy.sh first"
  exit 1
fi
echo "GitLab ClusterIP: $GITLAB_IP"

# --- Detect architecture for helper image ---
NODE_ARCH=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.architecture}')
HELPER_IMAGE=""
if [ "$NODE_ARCH" = "arm64" ]; then
  HELPER_IMAGE="registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:arm64-v18.8.0"
  echo "Detected ARM64 — using ARM helper image"
else
  HELPER_IMAGE="registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v18.8.0"
  echo "Detected x86_64"
fi

# --- Install/upgrade runner via Helm ---
echo ""
echo "Installing GitLab Runner via Helm..."

helm upgrade --install gitlab-runner gitlab/gitlab-runner \
  --namespace "$NAMESPACE" \
  --values "$VALUES_FILE" \
  --set runnerToken="$RUNNER_TOKEN" \
  --set certsSecretName=gitlab-runner-certs \
  --set "runners.config=[[runners]]
  clone_url = \"https://gitlab.gitlab.svc.cluster.local\"
  environment = [\"GIT_SSL_NO_VERIFY=true\"]
  [runners.kubernetes]
    namespace = \"$NAMESPACE\"
    image = \"alpine:latest\"
    pull_policy = [\"if-not-present\"]
    helper_image = \"$HELPER_IMAGE\"
    [[runners.kubernetes.host_aliases]]
      ip = \"$GITLAB_IP\"
      hostnames = [\"gitlab.local\"]
    [[runners.kubernetes.volumes.secret]]
      name = \"gitlab-tls\"
      mount_path = \"/etc/gitlab-runner/certs\"
      read_only = true
"

echo ""
echo "Waiting for runner pod..."
kubectl rollout status deployment/gitlab-runner -n "$NAMESPACE" --timeout=90s

echo ""
RUNNER_POD=$(kubectl get pods -n "$NAMESPACE" -l app=gitlab-runner \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$RUNNER_POD" ]; then
  echo "Runner pod: $RUNNER_POD"
  sleep 3
  echo ""
  echo "Runner logs (last 10 lines):"
  kubectl logs -n "$NAMESPACE" "$RUNNER_POD" --tail=10 2>/dev/null || true
fi

echo ""
echo "✓ GitLab Runner installed!"
echo ""
echo "Check status:  kubectl get pods -n $NAMESPACE -l app=gitlab-runner"
echo "Runner logs:   kubectl logs -f deployment/gitlab-runner -n $NAMESPACE"
echo ""
echo "NOTE: If CI jobs fail with 'Dependency Proxy' errors, disable it:"
echo "  Admin → Settings → CI/CD → Dependency Proxy → uncheck 'Enable'"
