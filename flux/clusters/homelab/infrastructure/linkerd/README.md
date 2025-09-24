# Linkerd Service Mesh

This directory contains the Linkerd service mesh configuration for the home infrastructure.

## Overview

Linkerd is a lightweight service mesh that provides:
- **Automatic mTLS**: Secure service-to-service communication
- **Observability**: Metrics, logs, and distributed tracing
- **Traffic Management**: Load balancing, retries, and circuit breaking
- **Security**: Policy enforcement and network segmentation

## Components

### Core Components

1. **Linkerd Control Plane** (`helmrelease.yaml`)
   - Main Linkerd control plane components
   - Includes identity, destination, proxy-injector, and tap services

2. **Linkerd Viz** (`linkerd-viz-helmrelease.yaml`)
   - Observability components
   - Includes Grafana, Prometheus, and the Linkerd dashboard

3. **Linkerd Jaeger** (`linkerd-jaeger-helmrelease.yaml`)
   - Distributed tracing with Jaeger
   - Provides request tracing across services

## Configuration

### Resource Limits

All components are configured with appropriate resource limits for a home environment:
- **CPU**: 100m-200m requests, 200m-400m limits
- **Memory**: 128Mi-256Mi requests, 256Mi-512Mi limits

### Storage

- **Jaeger**: Uses in-memory storage by default
- For production workloads, consider configuring persistent storage

## Usage

### Prerequisites

1. **Linkerd CLI**: Install the Linkerd CLI tool
   ```bash
   curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
   ```

2. **Cluster Access**: Ensure kubectl is configured for your cluster

### Deployment

Linkerd will be automatically deployed by Flux when the infrastructure is applied:

```bash
make up-studio
```

### Verification

Check Linkerd status:
```bash
make linkerd-status
```

Run health checks:
```bash
make linkerd-check
```

### Accessing the Dashboard

Port forward to the Linkerd dashboard:
```bash
make linkerd-dashboard
```

Then open http://localhost:8084 in your browser.

### Injecting Services

To add Linkerd to existing services:

1. **Namespace Injection** (recommended):
   ```bash
   make linkerd-inject
   # Enter namespace name when prompted
   ```

2. **Manual Injection**:
   ```bash
   kubectl get deployment my-app -o yaml | linkerd inject - | kubectl apply -f -
   ```

### Observability

#### Metrics

Linkerd automatically collects metrics for all injected services:
- Request rates and latencies
- Success rates and error rates
- Resource utilization

#### Tracing

Jaeger provides distributed tracing:
- Request flow visualization
- Performance bottleneck identification
- Service dependency mapping

#### Dashboards

- **Linkerd Dashboard**: Service overview and metrics
- **Grafana**: Custom dashboards and alerting
- **Prometheus**: Raw metrics and queries

## Integration with Existing Infrastructure

### Istio Coexistence

This setup includes both Istio and Linkerd. They can coexist but should not be used simultaneously for the same services:

- **Istio**: For complex traffic management and policy enforcement
- **Linkerd**: For simple service mesh with excellent observability

### Monitoring Integration

Linkerd integrates with the existing monitoring stack:
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **Tempo**: Distributed tracing (alternative to Jaeger)

## Security

### mTLS

Linkerd automatically enables mTLS between all injected services:
- No configuration required
- Automatic certificate rotation
- Zero-trust networking

### Network Policies

Linkerd works with Kubernetes Network Policies:
- Traffic is automatically encrypted
- Policies can be applied for additional security

## Troubleshooting

### Common Issues

1. **Proxy Injection Fails**
   ```bash
   # Check if the namespace has the required label
   kubectl get namespace my-namespace -o yaml
   # Should include: linkerd.io/inject: enabled
   ```

2. **Dashboard Not Accessible**
   ```bash
   # Check if the web service is running
   kubectl get pods -n linkerd -l app=linkerd-web
   ```

3. **Metrics Not Appearing**
   ```bash
   # Verify Prometheus is scraping Linkerd metrics
   kubectl get servicemonitor -n linkerd
   ```

### Useful Commands

```bash
# Check Linkerd status
make linkerd-status

# View control plane logs
make linkerd-logs

# Check proxy status
make linkerd-proxy-status

# Run health checks
make linkerd-check

# View metrics
make linkerd-metrics
```

## Advanced Configuration

### Custom Resource Limits

To modify resource limits, edit the HelmRelease values in:
- `helmrelease.yaml` - Control plane resources
- `linkerd-viz-helmrelease.yaml` - Observability resources
- `linkerd-jaeger-helmrelease.yaml` - Tracing resources

### High Availability

For production environments, enable high availability:
```yaml
# In helmrelease.yaml
highAvailability: true
```

### Persistent Storage

For Jaeger persistent storage:
```yaml
# In linkerd-jaeger-helmrelease.yaml
jaeger:
  storage:
    type: elasticsearch
    elasticsearch:
      nodeCount: 1
      storage: 10Gi
      storageClassName: fast-ssd
```

## References

- [Linkerd Documentation](https://linkerd.io/2.14/overview/)
- [Linkerd Helm Charts](https://github.com/linkerd/linkerd2/tree/main/charts)
- [Linkerd Best Practices](https://linkerd.io/2.14/overview/best-practices/)
