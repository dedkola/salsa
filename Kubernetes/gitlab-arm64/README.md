# GitLab CE Kubernetes Deployment

Deploy GitLab CE and GitLab Runner on Kubernetes using plain manifests.

## Prerequisites

- A running Kubernetes cluster (Docker Desktop K8s, minikube, kind, k3s, etc.)
- `kubectl` configured and pointing to your cluster
- An Ingress Controller installed:

**NGINX Ingress** (Docker Desktop, minikube, kind):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml
```

**k3s**: Traefik is included by default — no extra install needed. `deploy.sh` auto-detects and patches the Ingress.

## Manifest Files

| File                     | Description                                                    |
| ------------------------ | -------------------------------------------------------------- |
| `namespace.yaml`         | `gitlab` namespace                                             |
| `secrets.yaml`           | Placeholder secrets (reference only; `deploy.sh` creates them) |
| `gitlab-pvc.yaml`        | PVCs for config, logs, and data (1Gi / 5Gi / 50Gi)             |
| `gitlab-deployment.yaml` | GitLab CE Deployment with probes & TLS                         |
| `gitlab-service.yaml`    | ClusterIP Service (443, 80, 22)                                |
| `ingress.yaml`           | Ingress with TLS (NGINX default, auto-patched for Traefik)     |
| `kustomization.yaml`     | Kustomize manifest for GitLab resources                        |
| `deploy.sh`              | One-shot deploy script (generates secrets + applies manifests) |
| `runner-values.yaml`     | Helm values for the GitLab Runner chart                        |
| `register-runner.sh`     | Install/register runner via official Helm chart                |

## Setup

### 1. Deploy everything

```bash
./deploy.sh
```

This generates certs/passwords if missing, creates Kubernetes secrets, and applies all manifests.
It auto-detects NGINX vs Traefik (k3s) and patches the Ingress accordingly.

Or use kustomize (secrets must be created manually first via `deploy.sh`):

```bash
kubectl apply -k .
```

> **Note:** `kubectl apply -k .` applies resources only. Run `deploy.sh` at least once to generate certs and secrets.

### 2. Add hosts entry

```bash
echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts
```

### 3. Wait for GitLab

```bash
kubectl get pods -n gitlab -w
kubectl logs -f deployment/gitlab -n gitlab
```

Look for: `gitlab Reconfigured!` (takes 3-5 minutes)

### 4. Login to GitLab

- URL: https://gitlab.local (or the Ingress IP)
- Username: `root`
- Password: `cat secrets/gitlab_root_password.txt`

Accept the self-signed certificate warning in your browser.

### 5. Install the runner

Requires [Helm](https://helm.sh/docs/intro/install/) (the script installs it if missing).

1. Go to https://gitlab.local/admin/runners
2. Click **New instance runner**
3. Add tags (optional), click **Create runner**
4. Copy the token (starts with `glrt-`)
5. Run:

```bash
./register-runner.sh
```

Paste the token when prompted. This installs the runner via the [official GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes/), which handles registration, RBAC, TLS, and executor config automatically.

## Commands

| Command                                                            | Description          |
| ------------------------------------------------------------------ | -------------------- |
| `kubectl get pods -n gitlab`                                       | List pods            |
| `kubectl logs -f deployment/gitlab -n gitlab`                      | GitLab logs          |
| `kubectl logs -f deployment/gitlab-runner-gitlab-runner -n gitlab` | Runner logs          |
| `kubectl delete -k .`                                              | Tear down everything |

## Managing Runner Resources

### Check current resource limits

View the Helm configuration:

```bash
helm get values gitlab-runner -n gitlab
```

Or check the running pod:

```bash
kubectl get pod -n gitlab -l app=gitlab-runner \
  -o jsonpath='{.items[0].spec.containers[0].resources}' | \
  python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), indent=2))"
```

### Update memory/CPU limits

1. Edit `runner-values.yaml`:

```yaml
resources:
  requests:
    memory: "2Gi" # Minimum guaranteed
    cpu: "100m"
  limits:
    memory: "4Gi" # Maximum allowed
    cpu: "500m"
```

2. Apply the changes:

```bash
helm upgrade gitlab-runner gitlab/gitlab-runner \
  -n gitlab \
  -f runner-values.yaml \
  --reuse-values
```

3. Restart the runner pod to apply:

```bash
kubectl rollout restart deployment/gitlab-runner -n gitlab
kubectl rollout status deployment/gitlab-runner -n gitlab --timeout=90s
```

The runner will pick up the new limits after restart.

## Troubleshooting

### GitLab pod not starting

```bash
kubectl describe pod -l app.kubernetes.io/name=gitlab -n gitlab
kubectl logs deployment/gitlab -n gitlab
```

### Runner can't connect to GitLab

Ensure GitLab pod is ready:

```bash
kubectl get pods -n gitlab
```

The runner connects to GitLab via the in-cluster service `gitlab.gitlab.svc.cluster.local`.

### Deploying on k3s

k3s uses Traefik as the default ingress controller. `deploy.sh` automatically detects this and patches the Ingress. If deploying manually:

```bash
# Verify Traefik is running
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# Patch the Ingress for Traefik
kubectl patch ingress gitlab -n gitlab --type=json \
  -p='[{"op":"replace","path":"/spec/ingressClassName","value":"traefik"}]'
kubectl annotate ingress gitlab -n gitlab \
  "traefik.ingress.kubernetes.io/router.tls=true" \
  "traefik.ingress.kubernetes.io/service.serversscheme=https" --overwrite
```

### Runner registration lost after pod restart

The Helm chart handles runner configuration persistently. If the runner pod restarts, it picks up the config automatically. To change settings or re-register with a new token:

```bash
./register-runner.sh
```

This runs `helm upgrade`, which is idempotent.

### Reset everything

```bash
kubectl delete -k .
kubectl delete pvc --all -n gitlab
rm -rf ssl secrets
./deploy.sh
```

## Backup & Restore

### Create a backup

```bash
./backup.sh
```

This creates a timestamped folder in `backups/` containing:

| File                               | Contents                         |
| ---------------------------------- | -------------------------------- |
| `*_gitlab_backup.tar`              | Repos, DB, uploads, CI artifacts |
| `gitlab-secrets.json`              | Encryption keys (**critical**)   |
| `gitlab.rb`                        | GitLab configuration             |
| `ssl/`                             | TLS certificate & key            |
| `secrets/`                         | Root password                    |
| `gitlab-tls-secret.yaml`           | K8s TLS secret export            |
| `gitlab-root-password-secret.yaml` | K8s root password secret export  |

### Transfer to another cluster

1. Copy the backup folder to the target machine:
   ```bash
   scp -r k8s/backups/20260215-120000 user@target:/path/to/k8s/backups/
   ```
2. Copy the `k8s/` manifests folder too (or clone the repo).

3. On the target cluster, run:
   ```bash
   ./restore.sh backups/20260215-120000
   ```
   This will deploy GitLab, copy the backup in, restore the DB/repos, and restart.

### What gets backed up

- All Git repositories
- Database (users, projects, issues, merge requests, CI/CD config)
- Uploads and attachments
- CI/CD job artifacts
- LFS objects
- Encryption keys (`gitlab-secrets.json` — without this, encrypted data is unrecoverable)

### Important notes

- **`gitlab-secrets.json` is critical** — it contains the encryption keys for CI/CD variables, 2FA secrets, and other encrypted data. Without it, a restore will lose all encrypted content.
- Backups do **not** include the GitLab configuration (`gitlab.rb`) by default — the script copies it separately.
- Both clusters must run the **same major.minor GitLab version** for restore compatibility.
