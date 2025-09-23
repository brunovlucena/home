# 🔍 Cloudflare Tunnel Monitoring & Alerting

> **Comprehensive monitoring and alerting setup for Cloudflare Tunnel infrastructure**

This document describes the monitoring and alerting configuration for the Cloudflare Tunnel deployment, including Prometheus rules, canary monitoring, and troubleshooting procedures.

## 📊 Monitoring Components

### 1. **PrometheusRule - Tunnel Health Monitoring**

**File**: `prometheus-rule.yaml`

**Alerts Configured**:
- `CloudflareTunnelDown` - Pod down detection
- `CloudflareTunnelHighRestartRate` - Excessive restart detection
- `CloudflareTunnelHighMemoryUsage` - Memory usage alerts
- `CloudflareTunnelHighCPUUsage` - CPU usage alerts
- `CloudflareTunnelNotReady` - Readiness probe failures
- `CloudflareTunnelHealthCheckFailing` - Health check failures
- `CloudflareTunnelMetricsDown` - Metrics endpoint down
- `CloudflareTunnelMultiplePodsDown` - Multiple pod failures
- `CloudflareTunnelConnectionErrors` - Connection error tracking
- `CloudflareTunnelHighLatency` - Latency monitoring

### 2. **ServiceMonitor - Metrics Collection**

**File**: `servicemonitor.yaml`

**Configuration**:
- Scrapes metrics from `cloudflared-metrics` service
- 30-second collection interval
- 10-second scrape timeout
- HTTP scheme on port 2000

### 3. **Canary Monitoring - External Health Checks**

**File**: `canary-monitoring.yaml`

**External Probes**:
- **HTTP Probe**: `lucena.cloud` HTTP availability
- **HTTPS Probe**: `lucena.cloud` HTTPS availability  
- **DNS Probe**: DNS resolution from `1.1.1.1`

**Canary Alerts**:
- `LucenaCloudHTTPDown` - HTTP endpoint down
- `LucenaCloudHTTPSDown` - HTTPS endpoint down
- `LucenaCloudHighResponseTime` - Performance degradation
- `LucenaCloudSSLCertExpiring` - SSL certificate expiry
- `LucenaCloudDNSResolutionFailed` - DNS resolution issues
- `LucenaCloudMultipleEndpointsDown` - Multiple endpoint failures
- `LucenaCloudTunnelCorrelationAlert` - Tunnel correlation analysis

## 🚨 Alert Severity Levels

### **Critical Alerts**
- Tunnel pods down
- Multiple pods down
- Health checks failing
- External canary failures
- DNS resolution failures

### **Warning Alerts**
- High restart rate
- Resource usage high
- Response time degradation
- SSL certificate expiring
- Metrics endpoint issues

## 🔧 Troubleshooting Procedures

### **1. Tunnel Pod Down**

**Symptoms**: `CloudflareTunnelDown` alert firing

**Investigation Steps**:
```bash
# Check pod status
kubectl get pods -n cloudflare-tunnel

# Check pod events
kubectl describe pod -n cloudflare-tunnel -l app=cloudflared

# Check pod logs
kubectl logs -n cloudflare-tunnel -l app=cloudflared --tail=50
```

**Common Causes**:
- Invalid tunnel token
- Network connectivity issues
- Resource constraints
- Image pull failures

**Resolution**:
1. Verify tunnel token is valid in Cloudflare dashboard
2. Check network connectivity to Cloudflare edge
3. Review resource limits and requests
4. Restart deployment if necessary

### **2. High Restart Rate**

**Symptoms**: `CloudflareTunnelHighRestartRate` alert firing

**Investigation Steps**:
```bash
# Check restart count
kubectl get pods -n cloudflare-tunnel -o wide

# Check resource usage
kubectl top pods -n cloudflare-tunnel

# Check events for OOMKilled
kubectl get events -n cloudflare-tunnel --sort-by='.lastTimestamp'
```

**Resolution**:
1. Increase memory limits if OOMKilled
2. Check for application errors in logs
3. Verify tunnel configuration
4. Scale up replicas if needed

### **3. External Canary Failures**

**Symptoms**: `LucenaCloudHTTPDown` or `LucenaCloudHTTPSDown` alerts firing

**Investigation Steps**:
```bash
# Test external connectivity
curl -I http://lucena.cloud
curl -I https://lucena.cloud

# Check tunnel status in Cloudflare dashboard
# Verify DNS resolution
nslookup lucena.cloud

# Check tunnel logs for connection issues
kubectl logs -n cloudflare-tunnel -l app=cloudflared --tail=100
```

**Resolution**:
1. Verify tunnel is connected in Cloudflare dashboard
2. Check tunnel route configuration
3. Verify DNS records point to Cloudflare
4. Restart tunnel pods if necessary

### **4. False Positive Internet Connectivity**

**Symptoms**: Internet appears down but tunnel correlation alert shows tunnel issues

**Investigation Steps**:
```bash
# Check tunnel health
kubectl get pods -n cloudflare-tunnel

# Test direct internet connectivity
ping 8.8.8.8
curl -I https://google.com

# Check tunnel metrics
kubectl port-forward -n cloudflare-tunnel svc/cloudflared-metrics 2000:2000
curl http://localhost:2000/metrics
```

**Resolution**:
1. Focus on tunnel connectivity rather than internet connectivity
2. Check Cloudflare tunnel status
3. Verify tunnel token and configuration
4. Review tunnel logs for connection errors

## 📈 Metrics and Dashboards

### **Key Metrics to Monitor**

1. **Availability Metrics**:
   - `up{job="cloudflare-tunnel"}`
   - `probe_success{job="lucena-cloud-*"}`

2. **Performance Metrics**:
   - `probe_duration_seconds`
   - `cloudflared_tunnel_conns{event="latency"}`

3. **Resource Metrics**:
   - `container_memory_working_set_bytes`
   - `container_cpu_usage_seconds_total`

4. **Error Metrics**:
   - `cloudflared_tunnel_conns{event="connection_error"}`
   - `kube_pod_container_status_restarts_total`

### **Grafana Dashboard**

**Dashboard URL**: `https://grafana.home.local/d/cloudflare-tunnel`

**Key Panels**:
- Tunnel pod status and health
- External canary probe results
- Resource usage trends
- Error rate and restart patterns
- Response time trends

## 🔄 Maintenance Procedures

### **Regular Maintenance Tasks**

1. **Weekly**:
   - Review alert history and false positives
   - Check SSL certificate expiry dates
   - Review resource usage trends

2. **Monthly**:
   - Rotate tunnel tokens
   - Update tunnel configuration if needed
   - Review and update alert thresholds

3. **Quarterly**:
   - Review and update runbook procedures
   - Test alert escalation paths
   - Update monitoring configuration

### **Alert Threshold Tuning**

**Current Thresholds**:
- Restart rate: > 0.1 per minute
- Memory usage: > 80% of limit
- CPU usage: > 80% of limit
- Response time: > 5 seconds
- SSL expiry: < 30 days

**Tuning Guidelines**:
- Monitor false positive rates
- Adjust based on historical data
- Consider business impact
- Document threshold rationale

## 🚀 Deployment and Updates

### **Deploying Monitoring Changes**

```bash
# Apply monitoring configuration
kubectl apply -k flux/clusters/studio/infrastructure/cloudflare-tunnel/

# Verify PrometheusRule is loaded
kubectl get prometheusrule -n cloudflare-tunnel

# Verify ServiceMonitor is loaded
kubectl get servicemonitor -n cloudflare-tunnel

# Check probe configuration
kubectl get probe -n cloudflare-tunnel
```

### **Testing Alerts**

```bash
# Test critical alert (temporary)
kubectl apply -f flux/clusters/studio/infrastructure/prometheus-operator/test-critical-alert.yaml

# Verify alert fires in AlertManager
# Check Slack/PagerDuty notifications
# Clean up test alert
kubectl delete -f flux/clusters/studio/infrastructure/prometheus-operator/test-critical-alert.yaml
```

## 📚 References

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Prometheus Operator Documentation](https://github.com/prometheus-operator/prometheus-operator)
- [AlertManager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Kubernetes Monitoring Best Practices](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)

---

**Last Updated**: Created for Cloudflare Tunnel incident response  
**Maintained By**: Infrastructure Team  
**Review Cycle**: Monthly
