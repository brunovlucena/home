# Prometheus MCP Server

This service provides a Model Context Protocol (MCP) server for interacting with Prometheus metrics in the home infrastructure. It's based on the [AWS Prometheus MCP Server](https://awslabs.github.io/mcp/servers/prometheus-mcp-server/) but configured to work with the local kube-prometheus-stack installation.

## Features

- Execute instant PromQL queries against Prometheus
- Execute range queries with start time, end time, and step interval
- List all available metrics in your Prometheus instance
- Get server configuration information
- Automatic retries with exponential backoff

## Configuration

The service is configured through the `helmrelease.yaml` file. Key configuration options:

### Prometheus URL
```yaml
prometheus:
  url: "http://prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local:9090"
```

This points to the Prometheus service created by the kube-prometheus-stack Helm chart.

### Resource Allocation
Following the project's preferences for low CPU allocation:
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m  # Very low CPU allocation as preferred
    memory: 128Mi
```

## Deployment

The service is deployed via Flux GitOps and will be automatically applied when you run:

```bash
make flux-refresh
```

## Available Tools

The MCP server provides the following tools:

1. **GetAvailableWorkspaces** - List all available Prometheus workspaces
2. **ExecuteQuery** - Execute instant PromQL queries
3. **ExecuteRangeQuery** - Execute PromQL queries over a time range
4. **ListMetrics** - Retrieve all available metric names
5. **GetServerInfo** - Get server configuration details

## Usage with MCP Clients

### Configuration in settings.json

Add the following to your MCP client configuration:

```json
{
  "mcpServers": {
    "prometheus": {
      "httpUrl": "http://prometheus-mcp.prometheus-mcp.svc.cluster.local:8000",
      "timeout": 30000,
      "trust": true
    }
  }
}
```

### Example Usage

#### Get Available Workspaces
```python
workspaces = await get_available_workspaces()
for ws in workspaces['workspaces']:
    print(f"ID: {ws['workspace_id']}, Alias: {ws['alias']}, Status: {ws['status']}")
```

#### Execute an Instant Query
```python
result = await execute_query(
    workspace_id="local-prometheus",
    query="up"
)
```

#### Execute a Range Query
```python
data = await execute_range_query(
    workspace_id="local-prometheus",
    query="rate(node_cpu_seconds_total[5m])",
    start="2023-01-01T00:00:00Z",
    end="2023-01-01T01:00:00Z",
    step="1m"
)
```

#### List Available Metrics
```python
metrics = await list_metrics(
    workspace_id="local-prometheus"
)
```

## Troubleshooting

### Common Issues

1. **Connection Errors**
   - Verify Prometheus URL is correct
   - Check network connectivity between pods
   - Ensure Prometheus service is running

2. **Authentication Failures**
   - Verify Prometheus doesn't require authentication
   - Check if Prometheus is accessible from the MCP server pod

3. **Pod Not Starting**
   - Check pod logs: `kubectl logs -n prometheus-mcp <pod-name>`
   - Verify image can be pulled
   - Check resource limits and requests

### Debug Mode

Enable debug logging by updating the HelmRelease values:

```yaml
server:
  logLevel: "DEBUG"
  fastMCPLogLevel: "DEBUG"
```

## Architecture

The service consists of:
- **Deployment**: Runs the MCP server container
- **Service**: Exposes the MCP server on port 8000
- **ServiceAccount**: Provides identity for the pod
- **Namespace**: Isolates the service in `prometheus-mcp` namespace

## Security

- Runs as non-root user (UID 1000)
- Uses service account for authentication
- No persistent storage required
- Network policies can be applied for additional security

## Monitoring

The service includes:
- Liveness probe on `/health`
- Readiness probe on `/ready`
- Resource limits and requests
- Structured logging

## Dependencies

- Kubernetes cluster with kube-prometheus-stack installed
- Network access to Prometheus service
- `pab1it0/prometheus-mcp:latest` Docker image
