# 🔐 Sealed Secrets Infrastructure

This directory contains the Sealed Secrets infrastructure for the studio cluster.

## Overview

Sealed Secrets provides a way to encrypt Kubernetes secrets and store them safely in Git. The Sealed Secrets controller decrypts them and creates regular Kubernetes secrets.

## Components

- **repository.yaml**: HelmRepository for the Sealed Secrets chart
- **helmrelease.yaml**: HelmRelease to deploy Sealed Secrets controller
- **kustomization.yaml**: Kustomize configuration
- **create-bruno-secrets.sh**: Script to generate sealed secrets for Bruno Site

## Installation

The Sealed Secrets controller is automatically deployed by Flux when this infrastructure is applied.

## Usage

### 1. Generate Sealed Secrets for Bruno Site

```bash
# Navigate to this directory
cd sealed-secrets

# Generate sealed secrets for bruno-site namespace
./create-bruno-secrets.sh bruno-site
```

This will create:
- `bruno-site-db-secret.yaml` - Database password
- `bruno-site-redis-secret.yaml` - Redis password  
- `bruno-site-metrics-secret.yaml` - Metrics authentication

### 2. Apply the Sealed Secrets

```bash
# Apply all sealed secrets
kubectl apply -f .

# Or apply individually
kubectl apply -f bruno-site-db-secret.yaml
kubectl apply -f bruno-site-redis-secret.yaml
kubectl apply -f bruno-site-metrics-secret.yaml
```

### 3. Verify Secrets

```bash
# Check that secrets were created
kubectl get secrets -n bruno-site

# Check sealed secrets
kubectl get sealedsecrets -n bruno-site
```

## Prerequisites

- `kubeseal` CLI tool installed
- Sealed Secrets controller running in the cluster
- Access to the Kubernetes cluster

## Security Notes

- The generated passwords are cryptographically secure
- Sealed secrets can only be decrypted by the controller in the target cluster
- Store the generated passwords securely for local development
- Never commit unencrypted secrets to Git

## Troubleshooting

### Sealed Secrets Controller Not Running

```bash
# Check if controller is installed
kubectl get pods -n kube-system | grep sealed-secrets

# Install manually if needed
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
```

### kubeseal Not Found

```bash
# Install kubeseal
# macOS
brew install kubeseal

# Linux
# Download from https://github.com/bitnami-labs/sealed-secrets/releases
```

## Integration with Bruno Site

The Bruno Site Helm chart is configured to use these secrets:

- Database: `bruno-site-db-secret`
- Redis: `bruno-site-redis-secret`  
- Metrics: `bruno-site-metrics-secret`

The chart values should reference these secret names:

```yaml
database:
  existingSecret: "bruno-site-db-secret"

redis:
  existingSecret: "bruno-site-redis-secret"

security:
  metrics:
    existingSecret: "bruno-site-metrics-secret"
```
