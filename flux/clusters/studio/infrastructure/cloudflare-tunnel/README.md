# 🌐 Cloudflare Tunnel for Home Infrastructure

> **Secure tunnel deployment for exposing home services through Cloudflare Zero Trust**

This directory contains the Kubernetes manifests and configuration for deploying Cloudflare Tunnel in your home infrastructure, enabling secure access to your services without exposing them directly to the internet.

## 🎯 Overview

The Cloudflare Tunnel deployment provides:
- **Secure Connectivity**: Encrypted tunnel to Cloudflare's edge network
- **No Inbound Ports**: No need to open firewall ports or expose services directly
- **Zero Trust Security**: Integrates with Cloudflare Access for authentication
- **High Availability**: Multiple replicas for redundancy
- **Monitoring**: Built-in metrics and health checks

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Internet      │    │   Cloudflare    │    │   Kubernetes    │
│   Users         │───▶│   Edge Network  │───▶│   Home Cluster  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Zero Trust    │    │   cloudflared   │
                       │   Access        │    │   Pods          │
                       └─────────────────┘    └─────────────────┘
```

## 📁 Files Structure

```
cloudflare-tunnel/
├── 📄 README.md                           # 📖 This documentation
├── 📄 SETUP.md                            # 🚀 Quick setup guide
├── 📄 namespace.yaml                      # 🏷️  Namespace definition
├── 📄 deployment.yaml                     # 🚀 cloudflared deployment
├── 📄 service.yaml                        # 🌐 Metrics service
├── 📄 kustomization.yaml                  # ⚙️  Kustomize configuration
├── 📄 example-service.yaml                # 🧪 Test service (httpbin)
└── 📄 create-tunnel-sealed-secret.sh      # 🔐 Sealed secret creation script
```

## 🚀 Quick Start

### Prerequisites

1. **Cloudflare Account**: You need a Cloudflare account with Zero Trust enabled
2. **Domain**: A domain managed by Cloudflare
3. **Kubernetes Cluster**: Running Kind cluster with Flux GitOps

### Step 1: Create Tunnel in Cloudflare Dashboard

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** > **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** connector type
5. Enter a name (e.g., `home-infrastructure`)
6. Click **Save tunnel**
7. **Copy the tunnel token** (starts with `eyJhIjoi...`)

### Step 2: Create Tunnel Sealed Secret

Use the provided script to create the tunnel token sealed secret:

```bash
cd flux/clusters/studio/infrastructure/cloudflare-tunnel
./create-tunnel-sealed-secret.sh "your_tunnel_token_here"
```

This will create a `tunnel-token-sealed-secret.yaml` file that can be safely committed to Git.

### Step 3: Include Sealed Secret in Kustomization

After creating the sealed secret, uncomment the line in `kustomization.yaml`:

```yaml
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - tunnel-token-sealed-secret.yaml  # Uncomment this line
```

### Step 4: Deploy Tunnel

The tunnel will be automatically deployed by Flux GitOps. If you want to deploy manually:

```bash
kubectl apply -k flux/clusters/studio/infrastructure/cloudflare-tunnel/
```

### Step 5: Verify Deployment

Check that the tunnel pods are running:

```bash
kubectl get pods -n cloudflare-tunnel
kubectl logs -n cloudflare-tunnel -l app=cloudflared
```

### Step 6: Configure Tunnel Routes

1. Go back to the Cloudflare Zero Trust dashboard
2. Navigate to **Networks** > **Tunnels**
3. Click on your tunnel name
4. Go to **Public hostnames** tab
5. Add a route (e.g., `home.yourdomain.com` → `http://your-service:port`)

## 🧪 Testing with Example Service

To test the tunnel connectivity, you can deploy the included httpbin example service:

```bash
# Deploy the example service
kubectl apply -f example-service.yaml

# Configure a tunnel route in Cloudflare dashboard:
# Public hostname: test.yourdomain.com
# Service: http://httpbin-service.cloudflare-tunnel.svc.cluster.local
```

## 🔧 Configuration

### Environment Variables

The deployment uses the following environment variables:

- `TUNNEL_TOKEN`: Cloudflare tunnel token (from secret)

### Resource Limits

Default resource allocation:
- **CPU**: 50m request, 100m limit
- **Memory**: 64Mi request, 128Mi limit

### Security Context

- Runs as non-root user (65532)
- No privilege escalation
- All capabilities dropped
- ICMP traffic allowed for ping/traceroute

## 📊 Monitoring

### Metrics

The tunnel exposes metrics on port 2000:
- **Endpoint**: `http://cloudflared-metrics.cloudflare-tunnel.svc.cluster.local:2000/metrics`
- **Health Check**: `http://cloudflared-metrics.cloudflare-tunnel.svc.cluster.local:2000/ready`

### Logs

View tunnel logs:

```bash
kubectl logs -n cloudflare-tunnel -l app=cloudflared -f
```

### Health Checks

The deployment includes:
- **Liveness Probe**: Checks `/ready` endpoint every 10 seconds
- **Readiness Probe**: Checks `/ready` endpoint every 5 seconds

## 🔒 Security Considerations

### Secret Management

- Tunnel tokens are stored as sealed secrets (encrypted and Git-safe)
- Use the provided script to create sealed secrets
- Sealed secrets are automatically decrypted by the controller in the cluster
- No sensitive data is stored in plain text in Git

### Network Security

- No inbound ports required
- All traffic encrypted through Cloudflare
- Integrate with Cloudflare Access for authentication

### Token Rotation

Regularly rotate tunnel tokens:
1. Create new tunnel in Cloudflare dashboard
2. Update secret with new token
3. Delete old tunnel

## 🐛 Troubleshooting

### Common Issues

1. **Pods Not Starting**
   ```bash
   kubectl describe pod -n cloudflare-tunnel -l app=cloudflared
   kubectl logs -n cloudflare-tunnel -l app=cloudflared
   ```

2. **Tunnel Not Connecting**
   - Verify tunnel token is correct
   - Check Cloudflare dashboard for tunnel status
   - Ensure no firewall blocking outbound HTTPS traffic

3. **Routes Not Working**
   - Verify DNS records point to Cloudflare
   - Check tunnel route configuration in dashboard
   - Ensure service is accessible within cluster

### Useful Commands

```bash
# Check tunnel status
kubectl get pods -n cloudflare-tunnel

# View tunnel logs
kubectl logs -n cloudflare-tunnel -l app=cloudflared -f

# Check metrics
kubectl port-forward -n cloudflare-tunnel svc/cloudflared-metrics 2000:2000
curl http://localhost:2000/metrics

# Test connectivity
kubectl exec -n cloudflare-tunnel -l app=cloudflared -- curl -s http://localhost:2000/ready
```

## 🔄 Integration with Home Infrastructure

This tunnel deployment integrates with the broader home infrastructure:

- **Flux GitOps**: Automatically deployed and managed
- **Monitoring**: Metrics can be scraped by Prometheus
- **Logging**: Logs collected by Alloy/Loki
- **Security**: Integrates with existing RBAC and network policies

## 📚 References

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Kubernetes Deployment Guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deployment-guides/kubernetes/)
- [Zero Trust Access](https://developers.cloudflare.com/cloudflare-one/policies/access/)

## 🤝 Contributing

This is part of the home infrastructure project. To contribute:

1. Make changes to the manifests
2. Test thoroughly in your environment
3. Update documentation as needed
4. Submit a pull request

---

**Built with ❤️ for secure home infrastructure**
