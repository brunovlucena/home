# Knative Operator Configuration

This directory contains the Flux configuration for deploying the Knative Operator in the studio cluster.

## Components

- **knative-operator**: The main operator that manages Knative Serving and Eventing
- **knative-serving**: Knative Serving configuration for serverless workloads
- **knative-eventing**: Knative Eventing configuration for event-driven applications

## Configuration Details

### Resource Allocation
Based on the notifi configuration, all components use:
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

### Monitoring
- Prometheus metrics enabled for all components
- Request metrics backend configured for Prometheus

## Dependencies

This configuration depends on:
- Flux CD for GitOps deployment
- Prometheus for metrics collection
- Kubernetes cluster with appropriate node labels and taints

## Usage

The configuration will be automatically deployed by Flux when committed to the repository. The operator will then manage the Knative Serving and Eventing components.

## Verification

After deployment, verify the installation:

```bash
# Check operator status
kubectl get pods -n knative-operator

# Check serving status  
kubectl get pods -n knative-serving

# Check eventing status
kubectl get pods -n knative-eventing

# Check KnativeServing resource
kubectl get knativeserving -n knative-serving

# Check KnativeEventing resource
kubectl get knativeeventing -n knative-eventing
```
