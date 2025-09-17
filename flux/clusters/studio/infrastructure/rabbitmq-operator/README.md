# RabbitMQ Operator Configuration

This directory contains the Flux configuration for deploying the RabbitMQ Cluster Operator in the studio environment.

## Components

- **rabbitmq-cluster-operator**: The main operator that manages RabbitMQ clusters
- **Metrics**: Prometheus metrics and ServiceMonitor for monitoring

## Configuration Details

### Resource Allocation
Based on the notifi configuration, the operator uses:
- **CPU Requests**: 100m
- **CPU Limits**: 1000m  
- **Memory Requests**: 100Mi
- **Memory Limits**: 1000Mi

### Node Selection
Components are configured to run on nodes with the `knative: "true"` label and tolerate the `knative` taint.

### Security
- Read-only root filesystem
- Non-root user execution
- No privilege escalation
- All capabilities dropped

### Features
- **Cert Manager Integration**: Enabled for automatic TLS certificate management
- **Metrics**: ServiceMonitor enabled for Prometheus integration
- **Monitoring**: Service endpoints exposed for metrics collection

## Dependencies

This configuration depends on:
- **cert-manager**: For TLS certificate management
- **Prometheus**: For metrics collection
- **Kubernetes**: Cluster with appropriate node labels and taints

## Usage

The operator will be automatically deployed by Flux when committed to the repository. Once deployed, it will manage RabbitMQ clusters defined by RabbitmqCluster custom resources.

## Verification

After deployment, verify the installation:

```bash
# Check operator status
kubectl get pods -n rabbitmq-operator

# Check operator deployment
kubectl get deployment -n rabbitmq-operator

# Check custom resource definitions
kubectl get crd | grep rabbitmq

# Check operator logs
kubectl logs -n rabbitmq-operator deployment/rabbitmq-cluster-operator
```

## Custom Resources

The operator provides the following custom resources:
- **RabbitmqCluster**: Defines RabbitMQ cluster instances
- **User**: Manages RabbitMQ users
- **Permission**: Manages user permissions
- **Queue**: Manages queues
- **Exchange**: Manages exchanges
- **Binding**: Manages queue bindings
- **Policy**: Manages queue policies

## Next Steps

After the operator is deployed, you can create RabbitMQ clusters using the RabbitmqCluster custom resource. See the `rabbitmq-cluster` directory for an example cluster configuration.
