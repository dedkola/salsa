# Glances Server Docker

Minimal Alpine Linux-based Docker image running Glances in server mode with full Docker container visibility and real host system metrics.

## About This Project

This project provides a lightweight, production-ready Docker container for [Glances](https://github.com/nicolargo/glances) - a cross-platform system monitoring tool. The container runs Glances in server mode with a web interface, allowing you to monitor system resources (CPU, memory, disk, network, processes, and all running Docker containers) from anywhere.

**Key Features:**
- 🐧 Minimal Alpine Linux base (pinned to `3.21` for reproducible builds)
- 📊 Real-time monitoring of CPU, memory, disk, network, processes
- 🐳 Full Docker container visibility (all containers shown in Glances UI)
- 🖥️ Real host metrics (not container-scoped) via `/proc` and `/sys` mounts
- 🌐 Modern web UI with responsive design
- 🔌 RESTful API for programmatic access
- 🔒 Least-privilege: no privileged mode, all mounts read-only

## Quick Start

### Using Docker Compose (Recommended)
```bash
docker compose up -d
```

Then open: **http://localhost:61208**

### Using Docker CLI
```bash
docker run -d \
  --name glances \
  -p 61208:61208 \
  --pid=host \
  --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/etc/os-release:ro \
  -e HOST_PROC=/host/proc \
  -e HOST_SYS=/host/sys \
  glances-server
```

## Step-by-Step Guide

### 1. Build the Docker Image

```bash
# Clone or navigate to the project directory
cd /path/to/glances-docked

# Build the image
docker build -t glances-server .

# Verify the build
docker images glances-server
```

### 2. Run the Container

**Option A: Using Docker Compose**
```bash
# Start the container
docker compose up -d

# View logs
docker compose logs -f

# Stop the container
docker compose down
```

**Option B: Using Docker CLI**
```bash
# Run the container
docker run -d \
  --name glances \
  -p 61208:61208 \
  --pid=host \
  --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/etc/os-release:ro \
  -e HOST_PROC=/host/proc \
  -e HOST_SYS=/host/sys \
  glances-server

# View logs
docker logs -f glances

# Stop the container
docker stop glances && docker rm glances
```

### 3. Tag the Image

```bash
# Tag for Docker Hub (replace 'yourusername' with your Docker Hub username)
docker tag glances-server yourusername/glances-server:latest

# Verify tags
docker images | grep glances-server
```

### 4. Deploy to Docker Hub

```bash
# Login to Docker Hub
docker login

# Push the image
docker push yourusername/glances-server:latest
```

### 5. Pull and Run from Docker Hub

```bash
# Pull the image (on any machine)
docker pull yourusername/glances-server:latest

# Run the container
docker run -d \
  --name glances \
  -p 61208:61208 \
  --pid=host \
  --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/etc/os-release:ro \
  -e HOST_PROC=/host/proc \
  -e HOST_SYS=/host/sys \
  yourusername/glances-server:latest
```

## Access Methods

### Web Interface
Open your browser and navigate to:
- **Local**: http://localhost:61208
- **Remote**: http://YOUR_SERVER_IP:61208

### RESTful API
Access system metrics programmatically:
```bash
# Get API version
curl http://localhost:61208/api/4/status

# Get CPU info
curl http://localhost:61208/api/4/cpu

# Get memory info
curl http://localhost:61208/api/4/mem

# Get Docker container info
curl http://localhost:61208/api/4/docker

# Get all stats
curl http://localhost:61208/api/4/all
```

### Glances Client Mode
Connect from another machine using the Glances client:
```bash
# Install glances on client machine
pip install glances

# Connect to the server
glances -c YOUR_SERVER_IP -p 61208
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `UTC` | Container timezone |
| `HOST_PROC` | `/host/proc` | Path to mounted host `/proc` |
| `HOST_SYS` | `/host/sys` | Path to mounted host `/sys` |

### Volume Mounts

| Mount | Purpose |
|-------|---------|
| `/var/run/docker.sock:/var/run/docker.sock:ro` | Docker container visibility |
| `/proc:/host/proc:ro` | Host CPU, memory, process metrics |
| `/sys:/host/sys:ro` | Host hardware info |
| `/etc/os-release:/etc/os-release:ro` | Host OS identification |

### Ports
- `61208`: Web interface and API (default Glances web port)

## Docker Image Details

**Base Image**: Alpine Linux 3.21 (pinned)
**Installed Python Packages**:
- `glances[web]` — monitoring core + web UI (FastAPI/Uvicorn)
- `docker` — Docker SDK for Python (required for container visibility)
- `psutil` — system metrics (installed as glances dependency)

## Security Considerations

- `privileged: false` — no elevated container privileges
- All volume mounts use `:ro` (read-only)
- `pid: host` is required for Glances to enumerate host processes
- Port `61208` binds to all interfaces by default — use firewall rules or bind to `127.0.0.1:61208:61208` if external access is not needed
- Consider adding Glances authentication for production use

## Troubleshooting

### Container won't start
```bash
docker logs glances-server
```

### Can't access web interface
```bash
# Verify container is running
docker ps | grep glances

# Test locally
curl http://localhost:61208/api/4/status
```

### Docker containers not showing in Glances
- Ensure `/var/run/docker.sock` is mounted (already in `docker-compose.yml`)
- The `docker` Python package must be installed in the image (already in `Dockerfile`)
- Check logs for socket permission errors: `docker compose logs glances`

### Host metrics show container values instead of host values
- Ensure `/proc` and `/sys` are mounted to `/host/proc` and `/host/sys`
- Ensure `HOST_PROC` and `HOST_SYS` env vars are set (already in `docker-compose.yml`)

## Project Structure

```
.
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Docker Compose configuration
├── .dockerignore           # Docker build exclusions
├── docs/
│   └── plans/              # Implementation plans
└── README.md               # This file
```

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This project is open source. Glances itself is licensed under LGPL-3.0.

## Links

- **Glances Official**: https://github.com/nicolargo/glances
- **Glances Documentation**: https://glances.readthedocs.io/
- **Docker Hub**: https://hub.docker.com/r/yourusername/glances-server

## Changelog

### v1.1.0
- Added `docker` Python package for full Docker container visibility
- Added host `/proc`, `/sys`, `/etc/os-release` mounts for real host metrics
- Added `HOST_PROC` and `HOST_SYS` environment variables
- Pinned base image to `alpine:3.21` for reproducible builds
- Removed deprecated `version` field from `docker-compose.yml`

### v1.0.0 (2025-11-12)
- Initial release
- Alpine Linux base
- Glances with web UI
- FastAPI integration
- Docker Compose support
