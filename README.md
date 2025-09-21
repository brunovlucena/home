# 🏠 Home Infrastructure

> **Personal Kubernetes infrastructure for local development and home services**

This repository contains the infrastructure-as-code setup for my personal development environment, built with **Pulumi** and **Flux** for GitOps-driven Kubernetes management.

## 🎯 Overview

The `@home/` project provides a complete local Kubernetes infrastructure setup using:
- **Kind** for local cluster management
- **Pulumi** for infrastructure provisioning
- **Flux** for GitOps and continuous deployment
- **Cloudflare** for DNS management and external access

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Pulumi        │    │   Flux          │    │   Kubernetes    │
│   Infrastructure│───▶│   GitOps        │───▶│   Kind Cluster  │
│   as Code       │    │   Controller    │    │   (Studio)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   GitHub        │    │   Infrastructure│
│   DNS & Tokens  │    │   Container Reg │    │   Components    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
home/
├── 📄 Makefile              # 🛠️  Automation commands
├── 📄 README.md             # 📖 This file
├── 📄 LICENSE               # ⚖️  MIT License
├── 📄 .gitignore            # 🚫 Git ignore rules
├── 📁 pulumi/               # 🏗️  Infrastructure as Code
│   ├── 📄 main.go           # 🐹 Pulumi Go program
│   ├── 📄 Pulumi.yaml       # ⚙️  Pulumi configuration
│   ├── 📄 go.mod            # 📦 Go dependencies
│   └── 📄 go.sum            # 🔒 Go checksums
├── 📁 flux/                 # 🔄 GitOps configuration
│   └── 📁 clusters/         # 🎯 Cluster-specific configs
│       └── 📁 studio/       # 🖥️  Mac Studio cluster
│           ├── 📄 kind.yaml # 🐳 Kind cluster config
│           ├── 📄 kustomization.yaml
│           └── 📁 infrastructure/ # 🏗️  K8s resources
└── 📁 bruno/                # 🧑‍💻 Personal workspace
    └── 📁 repos/            # 📚 Repository management
```

## 🚀 Quick Start

### Prerequisites

- **Docker** with Kind support
- **kubectl** for Kubernetes management
- **Pulumi CLI** for infrastructure provisioning
- **Flux CLI** for GitOps operations
- **Go** for Pulumi program compilation

### Environment Setup

1. **Set required environment variables:**

```bash
# GitHub token for container registry access
export GITHUB_TOKEN="your_github_token"

# Cloudflare API token for DNS management
export CLOUDFLARE_TOKEN="your_cloudflare_token"

# Optional: GitHub username (defaults to brunovlucena)
export GITHUB_USERNAME="your_github_username"
```

2. **Initialize the Pulumi stack:**

```bash
make init-studio
```

3. **Deploy the infrastructure:**

```bash
make up-studio
```

## 🛠️ Available Commands

### Infrastructure Management

| Command | Description |
|---------|-------------|
| `make init-studio` | 🏗️ Initialize Pulumi studio stack |
| `make up-studio` | 🚀 Deploy studio stack (Mac Studio) |
| `make destroy-studio` | 💥 Destroy studio stack |
| `make flux-refresh` | 🔄 Force refresh all Flux resources |

### Flux Operations

| Command | Description |
|---------|-------------|
| `make flux-refresh` | 🔄 Refresh HelmRepositories, GitRepositories, and HelmReleases |
| `make flux-refresh-bruno` | 🔄 Refresh Bruno-specific Flux resources |

## 🔧 Infrastructure Components

### Core Infrastructure

- **Kind Cluster**: Local Kubernetes cluster named "studio"
- **Flux Controllers**: GitOps operators for continuous deployment
- **Cert Manager**: SSL certificate management
- **External DNS**: Automatic DNS record management
- **Cloudflare DDNS**: Dynamic DNS updates
- **Cloudflare Tunnel**: Secure tunnel for external access without exposing ports

### Security & Secrets

- **GitHub Secrets**: Container registry authentication
- **Cloudflare Secrets**: DNS management tokens
- **Docker Registry**: GHCR.io access credentials

### Observability

- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization and dashboards
- **Tempo**: Distributed tracing
- **Alloy**: Log aggregation

## 🌐 Network Configuration

The infrastructure is configured to work with:
- **Local Development**: Kind cluster on Mac Studio
- **External Access**: Cloudflare DNS and tunneling
- **Container Registry**: GitHub Container Registry (GHCR.io)

### Cloudflare Tunnel

The infrastructure includes a Cloudflare Tunnel deployment for secure external access:
- **No Inbound Ports**: Services are accessible without opening firewall ports
- **Zero Trust Security**: Integrates with Cloudflare Access for authentication
- **High Availability**: Multiple replicas with health checks
- **Monitoring**: Built-in metrics and logging

**Quick Setup:**
1. Create tunnel in [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Run: `./flux/clusters/studio/infrastructure/cloudflare-tunnel/create-tunnel-sealed-secret.sh <token>`
3. Uncomment sealed secret in kustomization.yaml
4. Configure routes in Cloudflare dashboard

See [Cloudflare Tunnel Setup Guide](flux/clusters/studio/infrastructure/cloudflare-tunnel/SETUP.md) for detailed instructions.

## 🔄 GitOps Workflow

1. **Infrastructure Changes**: Modify Pulumi code in `pulumi/main.go`
2. **Application Changes**: Update Flux manifests in `flux/clusters/studio/`
3. **Deployment**: Flux automatically syncs changes from Git
4. **Monitoring**: Check Flux status and logs

## 🤖 Dependabot & Self-Hosted Runners

The repository includes automated dependency management using Dependabot with self-hosted runners:

### 🔄 Automated Updates

- **📦 Go Dependencies** - Pulumi infrastructure code
- **🐳 Docker Dependencies** - Container configurations  
- **📋 GitHub Actions** - CI/CD workflow dependencies
- **🏗️ Flux Dependencies** - GitOps configurations
- **🔧 Script Dependencies** - Automation tools

### 🏷️ Self-Hosted Runner Configuration

All Dependabot PRs use self-hosted runners with labels:
- `self-hosted` - Identifies self-hosted runners
- `linux` - Operating system requirement
- `x64` - Architecture requirement
- `dependabot` - Specific label for Dependabot operations

### 🚀 Features

- ✅ **Automatic Detection** - Identifies Dependabot PRs
- 🧪 **Multi-Component Testing** - Tests all infrastructure components
- 🔒 **Security Scanning** - Runs Trivy security scans
- 📊 **Impact Analysis** - Analyzes dependency changes
- 🤖 **Auto-merge** - Automatically merges minor updates

See [`.github/README.md`](.github/README.md) for detailed setup instructions.

## 🐛 Troubleshooting

### Common Issues

1. **Missing Environment Variables**
   ```bash
   Error: GITHUB_TOKEN environment variable is required
   ```
   **Solution**: Set required environment variables before running `make up-studio`

2. **Kind Cluster Issues**
   ```bash
   Error: failed to create cluster
   ```
   **Solution**: Ensure Docker is running and has sufficient resources

3. **Flux Sync Issues**
   ```bash
   make flux-refresh
   ```

### Useful Commands

```bash
# Check cluster status
kubectl get nodes

# Check Flux resources
kubectl get flux -A

# Check Flux logs
kubectl logs -n flux-system -l app=source-controller

# Force Flux reconciliation
make flux-refresh
```

## 🔒 Security Considerations

- **Secrets Management**: All sensitive data is stored as Kubernetes secrets
- **Token Rotation**: Regularly rotate GitHub and Cloudflare tokens
- **Network Isolation**: Services are isolated in dedicated namespaces
- **RBAC**: Proper role-based access control is configured

## 📈 Monitoring & Observability

The infrastructure includes comprehensive monitoring:

- **Metrics**: Prometheus collects system and application metrics
- **Logs**: Centralized logging with Alloy
- **Traces**: Distributed tracing with Tempo
- **Dashboards**: Grafana provides visualization

## 🤝 Contributing

This is a personal infrastructure project, but contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Pulumi** for infrastructure as code
- **Flux** for GitOps automation
- **Kind** for local Kubernetes clusters
- **Cloudflare** for DNS and networking services

---

**Built with ❤️ for personal development and learning**
