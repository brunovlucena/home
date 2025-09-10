# 🚀 Cloudflare Tunnel Setup Guide

> **Quick setup guide for Cloudflare Tunnel in your home infrastructure**

## 📋 Prerequisites Checklist

- [ ] Cloudflare account with Zero Trust enabled
- [ ] Domain managed by Cloudflare
- [ ] Kubernetes cluster running (Kind with Flux)
- [ ] `kubectl` configured and working

## ⚡ Quick Setup (5 minutes)

### 1. Create Tunnel in Cloudflare (2 minutes)

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. **Networks** → **Tunnels** → **Create a tunnel**
3. Name: `home-infrastructure`
4. **Save tunnel** → **Copy the token** (starts with `eyJhIjoi...`)

### 2. Create Sealed Secret (1 minute)

```bash
cd flux/clusters/studio/infrastructure/cloudflare-tunnel
./create-tunnel-sealed-secret.sh "your_tunnel_token_here"
```

This creates an encrypted secret that's safe to commit to Git.

### 3. Include Sealed Secret (30 seconds)

Uncomment the sealed secret line in `kustomization.yaml`:

```yaml
resources:
  - tunnel-token-sealed-secret.yaml  # Uncomment this line
```

### 4. Deploy (automatic with Flux)

The tunnel will be deployed automatically by Flux GitOps. To check status:

```bash
kubectl get pods -n cloudflare-tunnel
```

### 5. Configure First Route (2 minutes)

1. Back to Cloudflare dashboard → Your tunnel
2. **Public hostnames** → **Add a public hostname**
3. **Subdomain**: `home` (or any subdomain)
4. **Domain**: `yourdomain.com`
5. **Service**: `http://your-service:port`
6. **Save hostname**

## 🧪 Test Your Setup

Deploy the test service:

```bash
kubectl apply -f example-service.yaml
```

Then configure a route:
- **Subdomain**: `test`
- **Service**: `http://httpbin-service.cloudflare-tunnel.svc.cluster.local`

Visit `https://test.yourdomain.com` to see the httpbin interface.

## ✅ Verification

```bash
# Check pods are running
kubectl get pods -n cloudflare-tunnel

# Check tunnel logs
kubectl logs -n cloudflare-tunnel -l app=cloudflared

# Test health endpoint
kubectl exec -n cloudflare-tunnel -l app=cloudflared -- curl -s http://localhost:2000/ready
```

## 🔧 Next Steps

1. **Add more routes** for your services
2. **Configure Cloudflare Access** for authentication
3. **Set up monitoring** with Prometheus
4. **Configure custom domains** for your services

## 🆘 Need Help?

- Check the [full README](README.md) for detailed documentation
- View logs: `kubectl logs -n cloudflare-tunnel -l app=cloudflared -f`
- Cloudflare docs: [Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

---

**🎉 You're all set! Your home services are now securely accessible through Cloudflare.**
