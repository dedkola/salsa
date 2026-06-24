#!/bin/bash
set -e

echo "=== GitLab CE Local Setup ==="

# Create directories
mkdir -p ssl secrets

# Generate root password
if [ ! -f secrets/gitlab_root_password.txt ]; then
  openssl rand -base64 24 > secrets/gitlab_root_password.txt
  echo "✓ Generated root password"
fi

# Generate self-signed SSL certificate
if [ ! -f ssl/gitlab.local.crt ]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/gitlab.local.key \
    -out ssl/gitlab.local.crt \
    -subj "/CN=gitlab.local" \
    -addext "subjectAltName=DNS:gitlab.local"
  echo "✓ Generated self-signed SSL certificate"
fi

echo ""
echo "=== Setup Complete ==="
echo "Root password: $(cat secrets/gitlab_root_password.txt)"
echo ""
echo "Next steps:"
echo "1. Add to /etc/hosts: 127.0.0.1 gitlab.local"
echo "2. Run: docker compose up -d"
echo "3. Wait ~3-5 min for GitLab to start"
echo "4. Access: https://gitlab.local"
echo "5. Login: root / <password above>"
echo "6. Run: ./register-runner.sh"