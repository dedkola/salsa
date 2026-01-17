# GitLab CE Local Setup (Docker Desktop)

Local GitLab CE instance with GitLab Runner using Docker Compose.

## Prerequisites

- Docker Desktop for macOS
- At least 10GB RAM allocated to Docker

## Setup

### 1. Run initial setup

```bash
./setup.sh
```

This generates:
- Root password in `secrets/gitlab_root_password.txt`
- Self-signed SSL certificate in `ssl/`

### 2. Add hosts entry

```bash
echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts
```

### 3. Start containers

```bash
docker compose up -d
```

Wait 3-5 minutes for GitLab to initialize. Check status:

```bash
docker compose logs -f gitlab
```

Look for: `gitlab Reconfigured!`

### 4. Login to GitLab

- URL: https://gitlab.local
- Username: `root`
- Password: run `./get-root-password.sh`

Accept the self-signed certificate warning in your browser.

### 5. Register the runner

1. Go to https://gitlab.local/admin/runners
2. Click **New instance runner**
3. Add tags (optional), click **Create runner**
4. Copy the token (starts with `glrt-`)
5. Run:

```bash
./register-runner.sh
```

Paste the token when prompted.

## Commands

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start GitLab |
| `docker compose down` | Stop GitLab |
| `docker compose logs -f gitlab` | View GitLab logs |
| `./get-root-password.sh` | Show root password |
| `./register-runner.sh` | Register a new runner |

## Troubleshooting

### GitLab not starting
```bash
docker compose logs gitlab
```

### Runner can't connect to GitLab
Ensure GitLab is healthy:
```bash
docker inspect gitlab --format='{{.State.Health.Status}}'
```

### Reset everything
```bash
docker compose down -v
rm -rf ssl secrets
./setup.sh
docker compose up -d
```
