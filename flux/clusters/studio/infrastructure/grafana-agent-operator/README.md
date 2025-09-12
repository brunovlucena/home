# Grafana Agent Operator

This directory contains the Grafana Agent Operator setup for the observability stack.

## Purpose

The Grafana Agent Operator provides Custom Resource Definitions (CRDs) required by other observability components, specifically:

- **PodLogs** (`monitoring.grafana.com/v1alpha1`) - Required by Loki for log collection
- **LogsInstance** - For log collection configuration
- **MetricsInstance** - For metrics collection configuration
- **Integration** - For various integrations

## Components

- **Namespace**: `grafana-agent-operator` - Dedicated namespace for operator resources
- **HelmRelease**: Deploys the grafana-agent-operator from Grafana Helm repository
- **CRDs**: Installs required Custom Resource Definitions

## Dependencies

This component must be deployed **before** Loki, as Loki requires the `PodLogs` CRD to be available.

## Configuration

- **Chart**: `grafana-agent-operator` version `0.4.0`
- **CRDs**: Automatically installed via `installCRDs: true`
- **Resources**: Minimal resource allocation (100m CPU, 128Mi memory)
- **Node Selector**: Deployed on nodes with `role: observability`

## Usage

The operator will be automatically deployed by Flux when this directory is applied. No manual configuration is required.

## Troubleshooting

If Loki fails with "no matches for kind 'PodLogs'", ensure this operator is deployed and the CRDs are installed:

```bash
# Check if CRDs are installed
kubectl get crd | grep monitoring.grafana.com

# Check operator status
kubectl get pods -n grafana-agent-operator

# Check CRD installation
kubectl get crd podlogs.monitoring.grafana.com
```

## Resources

- [Grafana Agent Operator Documentation](https://grafana.com/docs/agent/latest/static/flow/reference/components/grafana.agentoperator.v1/)
- [Grafana Agent Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana-agent-operator)
