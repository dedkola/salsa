#!/bin/bash
set -e

echo "=== GitLab Runner Registration (New Method) ==="
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

docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.local" \
  --token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-network-mode "gitlab-macos_gitlab_net" \
  --docker-extra-hosts "gitlab.local:$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gitlab)" \
  --tls-ca-file "/etc/gitlab-runner/certs/gitlab.local.crt"

echo ""
echo "✓ Runner registered successfully!"
docker exec gitlab-runner gitlab-runner list