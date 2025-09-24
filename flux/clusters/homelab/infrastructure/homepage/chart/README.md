# Bruno Site Helm Chart

This Helm chart deploys the Bruno Site application, which consists of:

- **API Service**: Go backend API running on port 8080
- **Frontend Service**: React frontend running on port 8080 (container) / 80 (service)
- **PostgreSQL Database**: PostgreSQL 15 database with persistent storage
- **Redis Cache**: Redis 7 cache with persistent storage
- **Database Initialization**: Kubernetes Job that runs migrations automatically

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Storage class for persistent volumes (optional, uses default if not specified)

## Installation

### Quick Start

```bash
# Add the repository (if using a Helm repository)
helm repo add bruno-site https://your-repo-url

# Install the chart
helm install bruno-site ./chart

# Or with custom values
helm install bruno-site ./chart --values values.yaml
```

### Development Installation

```bash
# Install with development images
helm install bruno-site-dev ./chart \
  --set api.image.tag=dev \
  --set frontend.image.tag=dev \
  --set ingress.enabled=false
```

## Configuration

The following table lists the configurable parameters of the bruno-site chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas for each service | `1` |
| `api.image.repository` | API image repository | `ghcr.io/brunovlucena/bruno-site-api` |
| `api.image.tag` | API image tag | `dev` |
| `api.image.pullPolicy` | API image pull policy | `IfNotPresent` |
| `api.service.type` | API service type | `ClusterIP` |
| `api.service.port` | API service port | `8080` |
| `api.resources` | API resource limits and requests | See values.yaml |
| `frontend.image.repository` | Frontend image repository | `ghcr.io/brunovlucena/bruno-site-frontend` |
| `frontend.image.tag` | Frontend image tag | `dev` |
| `frontend.image.pullPolicy` | Frontend image pull policy | `IfNotPresent` |
| `frontend.service.type` | Frontend service type | `ClusterIP` |
| `frontend.service.port` | Frontend service port | `80` |
| `frontend.appEnv` | Frontend environment | `production` |
| `frontend.resources` | Frontend resource limits and requests | See values.yaml |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `autoscaling.enabled` | Enable horizontal pod autoscaling | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `database.host` | PostgreSQL host | `postgresql` |
| `database.port` | PostgreSQL port | `5432` |
| `database.name` | PostgreSQL database name | `bruno_site` |
| `database.user` | PostgreSQL user | `postgres` |
| `redis.host` | Redis host | `redis` |
| `redis.port` | Redis port | `6379` |
| `corsOrigin` | CORS origin for API | `https://lucena.cloud` |

## Architecture

The chart creates the following Kubernetes resources:

### Deployments
- `bruno-site-api`: Go API backend
- `bruno-site-frontend`: React frontend
- `bruno-site-postgres`: PostgreSQL 15 database
- `bruno-site-redis`: Redis 7 cache

### Services
- `bruno-site-api`: Exposes API on port 8080
- `bruno-site-frontend`: Exposes frontend on port 80
- `bruno-site-postgres`: Exposes PostgreSQL on port 5432
- `bruno-site-redis`: Exposes Redis on port 6379

### Jobs
- `bruno-site-db-init`: Runs database migrations automatically on install/upgrade

### Persistent Volume Claims
- `bruno-site-postgres-pvc`: PostgreSQL data storage (8Gi by default)
- `bruno-site-redis-pvc`: Redis data storage (2Gi by default)

### Ingress
- Routes `/api/*` to the API service
- Routes `/*` to the frontend service

### Horizontal Pod Autoscalers
- Scales both API and frontend based on CPU/memory usage

## Environment Variables

### API Service
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `PORT`: API port (8080)
- `CORS_ORIGIN`: Allowed CORS origin

### Frontend Service
- `VITE_API_URL`: API endpoint URL (`/api`)
- `VITE_APP_ENV`: Application environment

## Health Checks

Both services include:
- **Liveness Probe**: HTTP GET `/health` every 30s
- **Readiness Probe**: HTTP GET `/health` every 5s

## Scaling

The chart includes horizontal pod autoscaling for both services:
- Scales based on CPU and memory utilization
- Configurable min/max replicas and target utilization

## Security

- Uses Kubernetes secrets for database passwords
- Supports existing secrets via `database.existingSecret`
- Configurable security contexts and pod security policies

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -l app.kubernetes.io/name=bruno-site
```

### View Logs
```bash
# API logs
kubectl logs -l app.kubernetes.io/component=api

# Frontend logs
kubectl logs -l app.kubernetes.io/component=frontend
```

### Port Forward for Local Access
```bash
# Frontend
kubectl port-forward svc/bruno-site-frontend 8080:80

# API
kubectl port-forward svc/bruno-site-api 8081:8080
```

## Upgrading

```bash
helm upgrade bruno-site ./chart
```

## Uninstalling

```bash
helm uninstall bruno-site
```
