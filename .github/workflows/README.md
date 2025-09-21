# 🏃‍♂️ Self-Hosted GitHub Actions Workflows

> **Privacy-focused CI/CD workflows using self-hosted runners**

This directory contains GitHub Actions workflows that use self-hosted runners in your home infrastructure, ensuring your code and build data remain private and are not used for training purposes.

## 🎯 Overview

The workflows in this directory demonstrate how to use self-hosted runners for:
- **Build and Test**: Compile and test your code locally
- **Container Builds**: Build Docker images on your infrastructure
- **Security Scanning**: Run security scans without external data sharing
- **Deployment**: Deploy to your home infrastructure
- **Cleanup**: Clean up resources and artifacts

## 🛡️ Privacy Benefits

### Data Protection
- **No External Sharing**: Your code never leaves your infrastructure
- **No Training Data**: Build logs and artifacts are not used for AI training
- **Full Control**: Complete control over data retention and access
- **Audit Trail**: All operations are logged locally

### Security Benefits
- **Network Isolation**: Runners operate within your secure network
- **Access Control**: Full control over who can access the runners
- **Secret Management**: Secrets are managed locally with sealed secrets
- **Compliance**: Meet data residency and privacy requirements

## 🚀 Quick Start

### 1. Setup Self-Hosted Runners

First, ensure your self-hosted runners are set up:

```bash
# From your home infrastructure directory
make github-runner-setup
make github-runner-status
```

### 2. Use in Your Workflows

Reference the self-hosted runners in your workflow files:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, x64, home-infrastructure]
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make build
```

### 3. Monitor Execution

Monitor your workflows:

```bash
# Check runner status
make github-runner-status

# View runner logs
make github-runner-logs

# Check metrics
make github-runner-metrics
```

## 📁 Workflow Examples

### `self-hosted-example.yml`
A comprehensive example showing:
- Build and test processes
- Container image building
- Security scanning
- Deployment to home infrastructure
- Resource cleanup

### Key Features:
- **Multi-job Pipeline**: Sequential and parallel job execution
- **Resource Monitoring**: CPU, memory, and disk usage tracking
- **Artifact Management**: Build reports and logs
- **Privacy Notices**: Clear documentation of data handling

## 🔧 Configuration

### Runner Labels
The workflows use these labels to target your self-hosted runners:
- `self-hosted`: Indicates self-hosted runner
- `linux`: Operating system
- `x64`: Architecture
- `home-infrastructure`: Custom label for your infrastructure

### Environment Variables
Set these in your repository secrets or workflow:
```yaml
env:
  RUNNER_LABELS: "self-hosted,linux,x64,home-infrastructure"
```

### Resource Limits
Runners are configured with:
- **CPU**: 100m request, 2000m limit
- **Memory**: 128Mi request, 4Gi limit
- **Storage**: Ephemeral volumes for work and temp directories

## 🛠️ Customization

### Adding New Workflows

1. Create a new `.yml` file in this directory
2. Use the self-hosted runner labels
3. Follow the privacy and security patterns
4. Include appropriate documentation

### Modifying Existing Workflows

1. Update the workflow file
2. Test with a small change first
3. Monitor resource usage
4. Update documentation as needed

### Adding New Runner Types

To add different types of runners (e.g., Windows, ARM):

1. Update the runner deployment configuration
2. Add new labels to the kustomization
3. Create workflows that use the new labels
4. Update documentation

## 📊 Monitoring

### Built-in Monitoring
- **Prometheus Metrics**: Runner performance and health
- **Grafana Dashboards**: Visualization of metrics
- **Loki Logs**: Centralized logging
- **Tempo Traces**: Distributed tracing

### Custom Monitoring
Add custom monitoring to your workflows:

```yaml
- name: Monitor resources
  run: |
    echo "CPU usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)"
    echo "Memory usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
    echo "Disk usage: $(df -h / | awk 'NR==2{printf "%s", $5}')"
```

## 🔒 Security

### Best Practices
- **Least Privilege**: Use minimal required permissions
- **Secret Rotation**: Regularly rotate GitHub tokens
- **Network Security**: Use network policies for isolation
- **Audit Logging**: Monitor all runner activities

### Security Scanning
Include security scanning in your workflows:

```yaml
- name: Security scan
  run: |
    # Run your preferred security tools
    echo "Running security scan..."
    # Add your security scanning commands here
```

## 🐛 Troubleshooting

### Common Issues

1. **Runner Not Available**:
   ```bash
   make github-runner-status
   make github-runner-restart
   ```

2. **Resource Limits**:
   ```bash
   make github-runner-metrics
   # Adjust limits in HelmRelease if needed
   ```

3. **Permission Issues**:
   ```bash
   make github-runner-logs
   # Check security context and permissions
   ```

### Debug Commands

```bash
# Check runner status
kubectl get runners -n github-actions-runner

# View runner logs
kubectl logs -n github-actions-runner -l app.kubernetes.io/name=github-actions-runner

# Check resource usage
kubectl top pods -n github-actions-runner

# View events
kubectl get events -n github-actions-runner --sort-by='.lastTimestamp'
```

## 📈 Performance

### Optimization Tips
- **Resource Tuning**: Adjust CPU/memory limits based on workload
- **Parallel Jobs**: Use matrix strategies for parallel execution
- **Caching**: Implement build caches for faster builds
- **Cleanup**: Regular cleanup of old artifacts and images

### Scaling
Scale runners based on demand:

```bash
# Scale to 5 runners
make github-runner-scale
# Enter 5 when prompted
```

## 📄 License

These workflows are part of the home infrastructure project and are licensed under the MIT License.

---

**Built with ❤️ for privacy-focused development**
