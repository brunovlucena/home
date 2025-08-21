# External DNS

This component deploys External DNS with Cloudflare provider to automatically manage DNS records for Kubernetes services and ingresses.

## Configuration

- **Provider**: Cloudflare
- **Domain**: lucena.cloud
- **Sources**: Services and Ingresses
- **Registry**: TXT records for ownership tracking
- **Update Interval**: 1 minute

## Prerequisites

1. Cloudflare API token with DNS management permissions
2. Secret `cloudflare-api-token` in the `external-dns` namespace with key `api-token`

## Features

- Automatically creates DNS records for services with `external-dns.alpha.kubernetes.io/hostname` annotation
- Automatically creates DNS records for ingresses
- Uses Cloudflare proxy for enhanced security and performance
- TXT record ownership tracking to prevent conflicts
- Health checks and monitoring

## Usage

To create DNS records for a service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.lucena.cloud
spec:
  # ... service spec
```

To create DNS records for an ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: myapp.lucena.cloud
    # ... ingress rules
```

## Security

- Runs as non-root user (UID 1000)
- Uses RBAC for minimal required permissions
- Security context prevents privilege escalation
- Health checks ensure service availability
