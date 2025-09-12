# RabbitMQ Cluster Configuration

This directory contains the Flux configuration for deploying a RabbitMQ cluster in the studio environment.

## Components

- **rabbitmq-cluster-studio**: The main RabbitMQ cluster instance
- **Users**: admin, notifi, and test users with appropriate credentials
- **Permissions**: Full access permissions for admin and notifi users
- **Queues**: Pre-configured queues for event processing including:
  - `kaniko-jobs`: Main job processing queue
  - `kaniko-jobs.dlq`: Dead letter queue for failed jobs
  - `dlx`: Dead letter exchange for routing failed messages

## Configuration Details

### Resource Allocation
Based on the notifi configuration, the cluster uses:
- **CPU Requests**: 100m
- **CPU Limits**: 500m  
- **Memory Requests**: 512Mi
- **Memory Limits**: 512Mi

### Node Selection
Components are configured to run on nodes with the `knative: "true"` label and tolerate the `knative` taint.

### Storage
- **Storage Class**: standard
- **Storage Size**: 1Gi
- **Persistence**: Enabled for data durability

### RabbitMQ Configuration
- **Image**: rabbitmq:3.12-management-alpine
- **Plugins**: rabbitmq_management enabled
- **Memory Limit**: 256MiB
- **Disk Free Limit**: 200MB
- **Heartbeat**: 60 seconds
- **Statistics**: Disabled for performance

### Queue Configuration
- **Queue Type**: Quorum queues for high availability
- **Message TTL**: 24 hours (86400000ms)
- **Max Length**: 10,000 messages
- **Overflow Policy**: drop-head
- **Dead Letter**: Enabled with separate DLQ

## Dependencies

This configuration depends on:
- **rabbitmq-operator**: Must be deployed first
- **cert-manager**: For TLS certificates
- **Prometheus**: For metrics collection (if monitoring enabled)

## Usage

The configuration will be automatically deployed by Flux when committed to the repository. The RabbitMQ cluster will be available at:

- **Management UI**: http://rabbitmq-cluster-studio.rabbitmq-studio.svc.cluster.local:15672
- **AMQP Port**: 5672
- **Management Port**: 15672

## Credentials

Default credentials (change in production):
- **admin**: admin/admin
- **notifi**: notifi/notifi  
- **test**: test/test

## Verification

After deployment, verify the installation:

```bash
# Check cluster status
kubectl get rabbitmqcluster -n rabbitmq-studio

# Check pods
kubectl get pods -n rabbitmq-studio

# Check users
kubectl get users -n rabbitmq-studio

# Check queues
kubectl get queues -n rabbitmq-studio

# Check permissions
kubectl get permissions -n rabbitmq-studio

# Port forward for management UI
kubectl port-forward -n rabbitmq-studio svc/rabbitmq-cluster-studio 15672:15672
```

## Monitoring

The cluster includes:
- ServiceMonitor for Prometheus metrics collection
- Management UI for queue monitoring
- Dead letter queue for failed message handling
