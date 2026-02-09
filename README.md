# Salsa

[![GitHub last commit](https://img.shields.io/github/last-commit/dedkola/salsa?style=flat-square)](https://github.com/dedkola/salsa/commits/main)
[![GitHub repo size](https://img.shields.io/github/repo-size/dedkola/salsa?style=flat-square)](https://github.com/dedkola/salsa)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=flat-square&logo=proxmox&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white)

> A collection of infrastructure-as-code configs, Docker Compose stacks, Kubernetes manifests, and automation scripts for a homelab environment.

**Full documentation:** [doc.tkweb.site](https://doc.tkweb.site/)

---

## Repository Structure

```
salsa/
├── Docker/                     # Docker Compose stacks
│   ├── Deluge/                 # BitTorrent client (web UI :8112)
│   ├── GitLab/
│   │   ├── gitlab-linux/       # GitLab CE for Linux with auto-registering runner
│   │   └── gitlab-macos/       # GitLab CE for macOS with SSL + setup scripts
│   ├── Gitea/                  # Lightweight Git service + PostgreSQL + Adminer
│   ├── HA/                     # Home Assistant dashboard config
│   ├── Mysql/                  # MySQL 8.0 + Adminer
│   ├── Mysql_wordpress/        # WordPress + MySQL 8.0 + Adminer
│   ├── Postgres/               # PostgreSQL + Adminer
│   ├── Prometheus/             # Prometheus server + node_exporter scraping
│   ├── build_image_wp_sql/     # Custom WordPress + MySQL Docker images
│   ├── flaresolverr/           # Cloudflare bypass proxy
│   ├── graylog_remote_mongodb/ # Graylog Enterprise 6.1 + Datanode (remote MongoDB)
│   ├── mongoDB/                # MongoDB + Mongo Express with auth
│   ├── nextjs_to_docker_container/  # Dockerfile for Next.js app deployment
│   ├── prowlarr/               # Indexer manager for Sonarr/Radarr
│   └── radarr/                 # Movie collection manager
│
├── Homepage/                   # Homepage dashboard (gethomepage.dev)
│   ├── docker.yaml             # Docker integration config
│   ├── services.yaml           # Monitored services definition
│   ├── settings.yaml           # Theme and layout settings
│   └── widgets.yaml            # Dashboard widgets (weather, system stats)
│
├── InfluxDB/                   # InfluxDB integrations
│   └── HA_integration_configuration.yaml  # Home Assistant → InfluxDB 2.0
│
├── Kubernetes/                 # Kubernetes manifests
│   ├── k3s/                    # K3s-specific deployments
│   │   ├── doc3.0/             # Next.js docs app (3 replicas, LB)
│   │   ├── graylog/            # Graylog Enterprise StatefulSet (2 replicas)
│   │   ├── mongodb/            # MongoDB with PVC (2Gi)
│   │   ├── mysql_single_pvc_lb/# MySQL 8.0 with tuned config (10Gi PVC)
│   │   └── postgres/           # PostgreSQL 17 with local-path storage
│   ├── mongodb/                # MongoDB deployment (3 replicas)
│   ├── mysql/                  # MySQL deployment (3 replicas)
│   ├── nextjs/                 # Next.js app (3 replicas)
│   ├── nginx/                  # Nginx examples (deployment, service, combined)
│   ├── services/               # Service type examples (MetalLB, NodePort)
│   └── wordpress_mysql/        # WordPress + MySQL full stack with PVCs
│
├── Prometheus/                 # Standalone Prometheus config
│   └── prometheus.yml          # Scrape config for node_exporters
│
├── Proxmox/                    # Proxmox VE automation
│   ├── create_template_cloud-init.sh  # Ubuntu cloud-init template creator
│   └── Read.me
│
├── Unbound/                    # DNS resolver config
│   └── conf.conf               # DNS-over-TLS to Cloudflare (1.1.1.1)
│
├── terrraform/                 # Terraform infrastructure-as-code
│   ├── k3s.tf                  # Proxmox K3s cluster (3 masters + 3 workers)
│   └── wsl.tf                  # WSL2 instance management
│
└── .github/
    └── dependabot.yml          # Weekly npm dependency updates
```

## Technologies

| Category | Tools |
|---|---|
| **Containers** | Docker, Docker Compose, K3s |
| **Databases** | MySQL 8.0, PostgreSQL, MongoDB, InfluxDB 2.0 |
| **CI/CD** | GitLab CE + Runner, Gitea, Dependabot |
| **Monitoring** | Prometheus, Graylog Enterprise, Glances |
| **Infrastructure** | Proxmox VE, Terraform, Cloud-init |
| **Web** | WordPress, Next.js, Nginx |
| **Networking** | Unbound DNS (DoT), MetalLB |
| **Media** | Radarr, Prowlarr, Deluge, FlareSolverr |
| **Smart Home** | Home Assistant, Homepage dashboard |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) and a running K3s cluster (for Kubernetes manifests)
- [Terraform](https://developer.hashicorp.com/terraform/install) (for infrastructure provisioning)
- [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview) (for VM template scripts)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/dedkola/salsa.git
   cd salsa
   ```

2. Navigate to the desired stack and deploy:
   ```bash
   # Example: start a MySQL + Adminer stack
   cd Docker/Mysql
   docker compose up -d

   # Example: deploy nginx to K3s
   kubectl apply -f Kubernetes/nginx/combined_app_and_service.yaml

   # Example: provision K3s cluster via Terraform
   cd terrraform
   terraform init && terraform apply
   ```

3. Check the [full documentation](https://doc.tkweb.site/) for detailed guides.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/add-new-stack`)
3. Commit your changes (`git commit -m 'Add new stack'`)
4. Push to the branch (`git push origin feature/add-new-stack`)
5. Open a Pull Request

## License

This project is open source. 
