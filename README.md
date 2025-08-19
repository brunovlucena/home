# Homelab Infrastructure

This repository contains the infrastructure code for my homelab setup using Pulumi, Flux, and Kubernetes.

## Overview

The homelab infrastructure is designed to run on a Mac Studio and includes:

- **Kubernetes Cluster**: Local Kind cluster for development and testing
- **GitOps with Flux**: Automated deployment and configuration management
- **Observability Stack**: Monitoring, logging, and tracing components
- **DDNS Management**: Cloudflare DNS updates for dynamic IP addresses
- **Container Registry**: GitHub Container Registry (GHCR) integration

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Pulumi CLI](https://www.pulumi.com/docs/install/)
- [Flux CLI](https://fluxcd.io/docs/installation/)

## Quick Start

1. **Setup Environment Variables**:
   ```bash
   make setup-env
   ```

2. **Deploy the Infrastructure**:
   ```bash
   make up-studio
   ```

3. **Check Status**:
   ```bash
   make status-studio
   ```

## Environment Variables

The following environment variables are required:

### GitHub Authentication
- `GITHUB_TOKEN`: GitHub Personal Access Token with `repo` and `workflow` scopes
- `GITHUB_USERNAME`: Your GitHub username (optional, defaults to `brunovlucena`)

### Cloudflare Authentication
- `CLOUDFLARE_TOKEN`: Cloudflare API Token with `Zone:Zone:Read` and `Zone:DNS:Edit` permissions

## Available Commands

```bash
# Setup and deployment
make setup-env          # Show environment variable setup instructions
make init-studio        # Initialize Pulumi studio stack
make up-studio          # Deploy studio stack
make destroy-studio     # Destroy studio stack
make refresh-studio     # Refresh Pulumi state against cluster

# Status and monitoring
make status-studio      # Show stack status
make logs-studio        # Show stack logs
```

## Architecture

### Stack Configuration
- **Stack Name**: `studio`
- **Cluster Name**: `studio`
- **Cluster Config**: `../flux/clusters/studio/kind.yaml`

### Components Deployed
1. **Kind Cluster**: Local Kubernetes cluster
2. **Flux Controllers**: GitOps operator installation
3. **GitHub Secret**: For Flux GitRepository authentication
4. **Docker Registry Secret**: For GHCR image pulls
5. **Cloudflare Secret**: For DDNS functionality
6. **Infrastructure Resources**: Deployed via Kustomize

### Infrastructure Components
The infrastructure is deployed from `../flux/clusters/studio/infrastructure/` and includes:
- Cert Manager for SSL/TLS certificates
- Observability stack (Prometheus, Grafana, etc.)
- Cloudflare DDNS for dynamic DNS updates
- Other platform services

## Troubleshooting

### Common Issues

1. **Missing Environment Variables**:
   ```bash
   # Check if variables are set
   echo $GITHUB_TOKEN
   echo $CLOUDFLARE_TOKEN
   
   # Set them if missing
   export GITHUB_TOKEN=your_token_here
   export CLOUDFLARE_TOKEN=your_token_here
   ```

2. **Pulumi Not Detecting Manifest Changes**:
   ```bash
   # If Pulumi doesn't detect removed resources, refresh the state
   make refresh-studio
   
   # Or manually refresh
   cd pulumi && pulumi refresh --yes
   ```

2. **Cluster Creation Issues**:
   ```bash
   # Check if Kind is installed
   kind version
   
   # Check Docker is running
   docker ps
   ```

3. **Flux Installation Issues**:
   ```bash
   # Check Flux CLI
   flux version
   
   # Check cluster connectivity
   kubectl get nodes
   ```

## Security Notes

- Environment variables contain sensitive tokens - never commit them to version control
- Use Kubernetes secrets for storing sensitive data in the cluster
- The Cloudflare token has minimal required permissions for DNS management only

## Contributing

1. Follow the existing code structure
2. Use Pulumi for infrastructure as code
3. Use Flux for GitOps deployments
4. Test changes in the studio environment first
