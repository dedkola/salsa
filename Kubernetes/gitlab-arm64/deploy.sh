#!/bin/bash
set -e

echo "=== GitLab CE Kubernetes Setup ==="

NAMESPACE="gitlab"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Prerequisites check ---
if ! command -v kubectl &>/dev/null; then
  echo "Error: kubectl is not installed"
  exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
  echo "Error: Cannot connect to Kubernetes cluster"
  echo "Ensure your kubeconfig is set and the cluster is running"
  exit 1
fi

echo "✓ Connected to cluster: $(kubectl config current-context)"

# --- Detect ingress controller ---
INGRESS_CLASS=""
if kubectl get ingressclass nginx &>/dev/null 2>&1; then
  INGRESS_CLASS="nginx"
  echo "✓ Detected NGINX Ingress Controller"
elif kubectl get ingressclass traefik &>/dev/null 2>&1; then
  INGRESS_CLASS="traefik"
  echo "✓ Detected Traefik Ingress Controller (k3s)"
else
  echo "⚠ No known ingress controller detected (nginx/traefik)"
  echo "  Install one before accessing GitLab via hostname"
fi

# --- Generate secrets if not present ---
mkdir -p "$SCRIPT_DIR/ssl" "$SCRIPT_DIR/secrets"

if [ ! -f "$SCRIPT_DIR/secrets/gitlab_root_password.txt" ]; then
  openssl rand -base64 24 > "$SCRIPT_DIR/secrets/gitlab_root_password.txt"
  echo "✓ Generated root password"
fi

if [ ! -f "$SCRIPT_DIR/ssl/gitlab.local.crt" ]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SCRIPT_DIR/ssl/gitlab.local.key" \
    -out "$SCRIPT_DIR/ssl/gitlab.local.crt" \
    -subj "/CN=gitlab.local" \
    -addext "subjectAltName=DNS:gitlab.local,DNS:gitlab.gitlab.svc.cluster.local,DNS:gitlab.gitlab.svc,DNS:gitlab.gitlab"
  echo "✓ Generated self-signed SSL certificate"
fi

# --- Create namespace ---
echo ""
echo "Creating namespace..."
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

# --- Create secrets from files ---
echo "Creating secrets..."

kubectl create secret generic gitlab-root-password \
  --from-file=gitlab_root_password="$SCRIPT_DIR/secrets/gitlab_root_password.txt" \
  --namespace "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret tls gitlab-tls \
  --cert="$SCRIPT_DIR/ssl/gitlab.local.crt" \
  --key="$SCRIPT_DIR/ssl/gitlab.local.key" \
  --namespace "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

# Runner Helm chart expects secret with key named <hostname>.crt
kubectl create secret generic gitlab-runner-certs \
  --from-file=gitlab.gitlab.svc.cluster.local.crt="$SCRIPT_DIR/ssl/gitlab.local.crt" \
  --namespace "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Secrets created"

# --- Deploy all resources ---
echo ""
echo "Deploying GitLab..."
kubectl apply -f "$SCRIPT_DIR/gitlab-pvc.yaml"
kubectl apply -f "$SCRIPT_DIR/gitlab-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/gitlab-service.yaml"
kubectl apply -f "$SCRIPT_DIR/ingress.yaml"

# --- Patch ingress for Traefik (k3s) if needed ---
if [ "$INGRESS_CLASS" = "traefik" ]; then
  echo ""
  echo "Patching Ingress for Traefik (k3s)..."
  kubectl patch ingress gitlab -n "$NAMESPACE" --type=json -p='[
    {"op":"replace","path":"/spec/ingressClassName","value":"traefik"},
    {"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1backend-protocol"},
    {"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1proxy-body-size"},
    {"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1proxy-read-timeout"},
    {"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1proxy-connect-timeout"},
    {"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1proxy-send-timeout"},
    {"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1proxy-buffer-size"}
  ]' 2>/dev/null || true
  kubectl annotate ingress gitlab -n "$NAMESPACE" \
    "traefik.ingress.kubernetes.io/router.tls=true" \
    "traefik.ingress.kubernetes.io/service.serversscheme=https" \
    --overwrite
  echo "✓ Ingress patched for Traefik"
fi

echo ""
echo "✓ All resources deployed"
echo ""
echo "=== Deployment Info ==="
echo "Namespace:  $NAMESPACE"
echo "Root pass:  $(cat "$SCRIPT_DIR/secrets/gitlab_root_password.txt")"
echo ""
echo "Wait 3-5 minutes for GitLab to initialize, then check:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl logs -f deployment/gitlab -n $NAMESPACE"
echo ""
echo "Access GitLab at: https://gitlab.local"
echo "(Ensure your /etc/hosts has: 127.0.0.1 gitlab.local)"
echo ""
echo "=== Next: Register Runner ==="
echo "Once GitLab is ready, run:"
echo "  ./register-runner.sh"
echo "This installs the Runner via the official Helm chart."
