# Gitea Actions runner on k3s

This directory contains the Helm values used to run a Gitea Actions runner on
the `k3s` Kubernetes context. The runner connects to the Gitea instance at
`http://192.168.0.97:3000/` and is installed in the `default` namespace.

The registration token is stored in a Kubernetes Secret. It must not be placed
directly in `values.yaml` or committed to Git.

## What is installed

The `gitea-charts/actions` chart creates:

- one runner StatefulSet and pod;
- a Gitea runner container;
- a Docker-in-Docker (DinD) sidecar used by Actions jobs;
- a ConfigMap containing the runner configuration;
- a persistent volume claim for runner registration data.

Current names:

| Resource     | Value                        |
| ------------ | ---------------------------- |
| Helm release | `gitea-actions`              |
| Namespace    | `default`                    |
| Runner pod   | `gitea-actions-runner-0`     |
| Token Secret | `gitea-actions-runner-token` |
| Secret key   | `token`                      |
| Gitea URL    | `http://192.168.0.97:3000/`  |

## 1. Prerequisites

Install and configure:

- a working k3s cluster;
- `kubectl` with access to the cluster;
- Helm 3;
- Gitea 1.19 or newer with Actions enabled.

Confirm that commands target the expected cluster:

```sh
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
helm version
```

The expected context for this setup is `k3s`. Do not continue if these commands
show a different production cluster.

## 2. Enable Actions in Gitea

Gitea Actions must be enabled for the instance and for the repository that will
run workflows.

For a repository, open:

```text
http://192.168.0.97:3000/<owner>/<repository>/settings
```

Enable **Repository Actions** in the repository settings. Gitea versions older
than 1.21 may also require this instance configuration:

```ini
[actions]
ENABLED=true
```

## 3. Generate a runner registration token

Choose the token scope that matches where the runner should be available:

- repository: `<owner>/<repository>/settings/actions/runners`;
- organization: `<organization>/settings/actions/runners`;
- instance: `/-/admin/actions/runners`.

Create or copy the registration token from that page. This is a runner
registration token, not a personal access token and not the workflow-provided
`GITEA_TOKEN`.

An instance administrator can alternatively generate a token on the Gitea
server:

```sh
gitea --config /etc/gitea/app.ini actions generate-runner-token
```

## 4. Store the token as a Kubernetes Secret

From a zsh terminal, read the token without displaying it and create the Secret:

```sh
read -r -s "RUNNER_TOKEN?Paste Gitea runner registration token: "
echo
printf %s "$RUNNER_TOKEN" |
  kubectl create secret generic gitea-actions-runner-token \
    --namespace default \
    --from-file=token=/dev/stdin \
    --dry-run=client \
    -o yaml |
  kubectl apply -f -
unset RUNNER_TOKEN
```

Confirm that the Secret and expected key exist without printing the token:

```sh
kubectl get secret gitea-actions-runner-token --namespace default
kubectl describe secret gitea-actions-runner-token --namespace default
```

`kubectl describe` should report one data entry named `token`.

## 5. Configure Helm values

The required portion of `values.yaml` is:

```yaml
enabled: true

existingSecret: "gitea-actions-runner-token"
existingSecretKey: "token"

giteaRootURL: "http://192.168.0.97:3000/"

statefulset:
  replicas: 1
```

`existingSecret` is the Kubernetes Secret name. `existingSecretKey` is the key
inside that Secret. Neither field should contain the actual registration token.

The URL must be reachable from both the runner pod and the containers created
for workflow jobs. Do not use `localhost` or `127.0.0.1`.

The complete configuration used by this installation is in
[`values.yaml`](./values.yaml).

## 6. Add the Gitea Helm repository

```sh
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update gitea-charts
helm search repo gitea-charts/actions --versions
```

## 7. Validate and install

Render the manifests locally first:

```sh
helm template gitea-actions gitea-charts/actions \
  --namespace default \
  --values ./values.yaml >/dev/null
```

Install or upgrade the release and wait for it to become ready:

```sh
helm upgrade --install gitea-actions gitea-charts/actions \
  --namespace default \
  --values ./values.yaml \
  --wait \
  --timeout 5m
```

The same command is safe to use for later configuration upgrades.

## 8. Verify the runner

Check the Helm release and Kubernetes resources:

```sh
helm status gitea-actions --namespace default
kubectl get statefulset,pod,pvc \
  --namespace default \
  --selector app.kubernetes.io/instance=gitea-actions \
  -o wide
```

Expected state:

```text
statefulset.apps/gitea-actions-runner   1/1
pod/gitea-actions-runner-0              2/2   Running
```

Confirm runner registration and inspect both containers:

```sh
kubectl logs gitea-actions-runner-0 \
  --namespace default \
  --container runner \
  --tail 100

kubectl logs gitea-actions-runner-0 \
  --namespace default \
  --container dind \
  --tail 100
```

The runner log should contain `declare successfully`. It should appear online
on the corresponding Gitea Actions runner settings page.

Follow a running job live:

```sh
kubectl logs gitea-actions-runner-0 \
  --namespace default \
  --container runner \
  --follow
```

## 9. Test with a workflow

Create `.gitea/workflows/runner-test.yaml` in a Gitea repository:

```yaml
name: Runner test

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Show runner environment
        run: |
          echo "Gitea runner is working"
          uname -a
          docker version
```

Commit and push the workflow, then start it from the repository Actions page.
The default chart configuration advertises these labels:

- `ubuntu-latest`
- `ubuntu-24.04`
- `ubuntu-22.04`

The workflow `runs-on` value must match one of the runner labels.

## 10. Upgrade the chart

Review available versions and the rendered change before upgrading:

```sh
helm repo update gitea-charts
helm search repo gitea-charts/actions --versions
helm template gitea-actions gitea-charts/actions \
  --namespace default \
  --values ./values.yaml >/dev/null
helm upgrade gitea-actions gitea-charts/actions \
  --namespace default \
  --values ./values.yaml \
  --wait \
  --timeout 5m
```

## 11. Rotate the registration token

Generate a new runner registration token in Gitea, then repeat step 4. Applying
the Secret replaces its `token` value.

An already registered runner stores its runner credentials on the persistent
volume. To force it to discard that registration and register again with the
new token:

```sh
helm upgrade gitea-actions gitea-charts/actions \
  --namespace default \
  --values ./values.yaml \
  --set statefulset.runner.flushCache=true \
  --wait \
  --timeout 5m

helm upgrade gitea-actions gitea-charts/actions \
  --namespace default \
  --values ./values.yaml \
  --set statefulset.runner.flushCache=false \
  --wait \
  --timeout 5m
```

Verify that the runner declares successfully after rotation.

## 12. Troubleshooting

### Helm is deployed but there are no pods

Check the effective value:

```sh
helm get values gitea-actions --namespace default --all | grep '^enabled:'
```

It must be `enabled: true`. With `enabled: false`, Helm reports a successful
release but the chart intentionally renders no runner resources.

### Secret not found or key not found

```sh
kubectl get secret gitea-actions-runner-token --namespace default
kubectl describe secret gitea-actions-runner-token --namespace default
kubectl describe pod gitea-actions-runner-0 --namespace default
```

Confirm that `values.yaml` references Secret `gitea-actions-runner-token` and key
`token` exactly.

### Pod is stuck in an init container

The chart waits until the Gitea URL is reachable. Inspect the init status and
events:

```sh
kubectl describe pod gitea-actions-runner-0 --namespace default
kubectl get events --namespace default --sort-by=.lastTimestamp
```

Check network reachability from the cluster. The configured URL must resolve or
route to Gitea from k3s nodes and pods.

### Runner is offline or registration fails

```sh
kubectl logs gitea-actions-runner-0 \
  --namespace default \
  --container runner \
  --tail 200
```

Confirm that the token is a runner registration token with the intended scope.
If it was reset in Gitea, update the Secret and follow the rotation procedure.

### Docker jobs fail

```sh
kubectl logs gitea-actions-runner-0 \
  --namespace default \
  --container dind \
  --tail 200
```

DinD requires privileged container capability. Check cluster admission policy,
pod events, storage availability, image pulls, DNS, and outbound registry access.

### Show all release resources

```sh
kubectl get all,configmap,pvc \
  --namespace default \
  --selector app.kubernetes.io/instance=gitea-actions
```

## 13. Uninstall

Remove the Helm-managed runner resources:

```sh
helm uninstall gitea-actions --namespace default
```

StatefulSet persistent volume claims and the manually created Secret may remain.
Inspect them before deciding whether to delete them:

```sh
kubectl get pvc --namespace default
kubectl get secret gitea-actions-runner-token --namespace default
```

Only when the runner registration data and token are no longer needed:

```sh
kubectl delete pvc data-runner-gitea-actions-runner-0 --namespace default
kubectl delete secret gitea-actions-runner-token --namespace default
```

Deleting the PVC removes the runner's persisted registration state. These
cleanup commands are not required for a normal Helm upgrade.

## References

- [Gitea Actions quick start](https://docs.gitea.com/usage/actions/quickstart/)
- [Gitea runner documentation](https://docs.gitea.com/usage/actions/act-runner/)
- [Gitea runner installation on Kubernetes](https://docs.gitea.com/runner/develop/installation/kubernetes/)
- [Gitea Actions Helm chart](https://gitea.com/gitea/helm-actions)
