# Cloudflare DDNS

This directory contains the Kubernetes deployment for [favonia/cloudflare-ddns](https://github.com/favonia/cloudflare-ddns), a lightweight Cloudflare DNS updater.

## Overview

The favonia/cloudflare-ddns is a small, feature-rich, and robust Cloudflare DDNS updater that:
- Updates DNS records automatically
- Supports multiple record types (A, AAAA, CNAME)
- Uses Cloudflare API tokens for authentication
- Runs as a lightweight container in Kubernetes

## Configuration

### Environment Variables

- `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token
- `DOMAIN`: The domain to update (e.g., `example.com`)
- `SUBDOMAIN`: The subdomain to update (e.g., `www` or `@` for root)
- `UPDATE_INTERVAL`: How often to check for IP changes (default: 5 minutes)

### DNS Record Types

- `A`: IPv4 address
- `AAAA`: IPv6 address
- `CNAME`: Canonical name

## Deployment

The deployment uses Flux with a HelmRelease to manage the cloudflare-ddns service.

## Security

- Uses Kubernetes secrets for API token storage
- Runs with minimal RBAC permissions
- Container runs as non-root user
