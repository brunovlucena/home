# GitHub Action Runners

This directory contains the infrastructure configuration for self-hosted GitHub Action runners using the [actions-runner-controller](https://github.com/actions-runner-controller/actions-runner-controller).

## Components

- **actions-runner-controller**: The main controller that manages GitHub Action runners
- **github-config-secret**: Secret containing GitHub authentication configuration
- **example-runner-deployment**: Sample RunnerDeployment for configuring runners

## Setup Instructions

### 1. Add Helm Repository

First, add the actions-runner-controller Helm repository to your Flux configuration:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: actions-runner-controller
  namespace: flux-system
spec:
  interval: 1h
  url: https://actions-runner-controller.github.io/actions-runner-controller
```

### 2. Configure GitHub Authentication

You have two options for GitHub authentication:

#### Option A: GitHub App (Recommended)

1. Create a GitHub App in your GitHub organization
2. Install the app in your repositories
3. Generate a private key
4. Update the `github-config-secret.yaml` with:
   - `github_app_id`: Your GitHub App ID
   - `github_app_installation_id`: Installation ID
   - `github_app_private_key`: Your private key

#### Option B: Personal Access Token

1. Create a Personal Access Token with `repo` and `admin:org` scopes
2. Update the `github-config-secret.yaml` with:
   - `github_token`: Your personal access token

### 3. Configure Runner Deployment

Update the `runner-deployment.yaml` with your specific configuration:

- `repository`: Your repository name (e.g., `your-username/your-repo`)
- `organization`: Your organization name (for org-wide runners)
- Resource limits and requests
- Runner labels and groups

### 4. Deploy

Add the action-runners directory to your main kustomization.yaml:

```yaml
resources:
  - action-runners/
```

## Usage

Once deployed, your runners will be available in GitHub and can be used in your workflows by specifying the runner labels:

```yaml
jobs:
  build:
    runs-on: self-hosted
    steps:
      - name: Checkout
        uses: actions/checkout@v4
```

## Monitoring

The controller exposes metrics that can be scraped by Prometheus. ServiceMonitor is enabled by default.

## Troubleshooting

1. Check the controller logs:
   ```bash
   kubectl logs -n action-runners deployment/actions-runner-controller
   ```

2. Check runner pod logs:
   ```bash
   kubectl logs -n action-runners -l actions-runner-controller/runner
   ```

3. Verify GitHub authentication:
   ```bash
   kubectl get secret -n action-runners github-config -o yaml
   ```
