# 🚀 A/B & Canary Deployment Plan

> **Comprehensive strategy for progressive delivery using Flux and Flagger**

This document outlines the implementation plan for A/B testing and Canary deployments in the `@home/` infrastructure, specifically designed for the `@bruno-site/` application using **Flux** for GitOps and **Flagger** for progressive delivery.

## 🎯 Overview

The plan implements a robust progressive delivery strategy that enables:
- **🔵 Canary Deployments**: Gradual traffic shifting with automatic rollback
- **🟢 A/B Testing**: Feature comparison with traffic splitting
- **🔄 Blue/Green Deployments**: Zero-downtime releases with instant rollback
- **📊 Automated Analysis**: Metrics-based promotion and rollback decisions

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flux          │    │   Flagger       │    │   Istio         │
│   GitOps        │───▶│   Progressive   │───▶│   Service Mesh  │
│   Controller    │    │   Delivery      │    │   Traffic Mgmt  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   Prometheus    │    │   Bruno Site    │
│   Container Reg │    │   Metrics       │    │   Application   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Implementation Structure

```
flux/clusters/studio/infrastructure/
├── 📁 flagger/                    # 🚦 Flagger Controller
│   ├── 📄 namespace.yaml          # 🏷️  Flagger namespace
│   ├── 📄 helmrelease.yaml        # 📦 Flagger Helm release
│   ├── 📄 gateway.yaml            # 🌐 Istio Gateway
│   └── 📄 kustomization.yaml      # 🔧 Kustomize config
├── 📁 bruno-site/                 # 🧑‍💻 Bruno Site App
│   ├── 📄 namespace.yaml          # 🏷️  Bruno namespace
│   ├── 📄 helmrelease.yaml        # 📦 App Helm release
│   ├── 📄 canary.yaml             # 🎯 Canary configuration
│   ├── 📄 destinationrule.yaml    # 🎯 Traffic routing rules
│   ├── 📄 virtualservice.yaml     # 🌐 Istio virtual service
│   └── 📄 kustomization.yaml      # 🔧 Kustomize config
└── 📁 prometheus-operator/        # 📊 Metrics collection
    └── 📄 ...                     # 📈 Monitoring stack
```

## 🚀 Deployment Strategies

### 1. 🔵 Canary Deployment

**Purpose**: Gradual traffic shifting with automatic rollback on failure

**Configuration**:
```yaml
# Progressive traffic shifting
spec:
  strategy: Canary
  canary:
    # Initial traffic percentage
    stepWeight: 10
    
    # Traffic increase steps
    maxWeight: 50
    
    # Analysis interval
    interval: 30s
    
    # Success threshold
    threshold: 10
    
    # Max failures before rollback
    maxFailures: 3
```

**Traffic Flow**:
```
100% → 90% + 10% → 80% + 20% → 50% + 50% → 100% (New)
Old     Old + New   Old + New   Old + New     New
```

### 2. 🟢 A/B Testing

**Purpose**: Feature comparison with traffic splitting

**Configuration**:
```yaml
# Traffic splitting for A/B testing
spec:
  strategy: A/B
  ab:
    # Traffic split percentage
    weight: 50
    
    # Analysis duration
    interval: 5m
    
    # Success criteria
    threshold: 15
    
    # Max failures
    maxFailures: 5
```

**Traffic Flow**:
```
50% → Version A (Control)
50% → Version B (Treatment)
```

### 3. 🔄 Blue/Green Deployment

**Purpose**: Zero-downtime releases with instant rollback

**Configuration**:
```yaml
# Blue/Green deployment
spec:
  strategy: BlueGreen
  
  blueGreen:
    # Traffic routing
    trafficRouting:
      istio:
        virtualService:
          name: bruno-site-vs
          routes:
          - name: primary
            weight: 100
          - name: canary
            weight: 0
```

**Traffic Flow**:
```
100% → Blue (Current) → 100% → Green (New)
Old                    Switch   New
```

## 📊 Metrics & Analysis

### Core Metrics

1. **Request Success Rate**
   ```yaml
   metrics:
   - name: request-success-rate
     thresholdRange:
       min: 99
     interval: 1m
   ```

2. **Request Duration**
   ```yaml
   metrics:
   - name: request-duration
     thresholdRange:
       max: 500
     interval: 1m
   ```

3. **Error Rate**
   ```yaml
   metrics:
   - name: error-rate
     thresholdRange:
       max: 1
     interval: 1m
   ```

### Custom Metrics

4. **Business Metrics**
   ```yaml
   metrics:
   - name: conversion-rate
     thresholdRange:
       min: 2.5
     interval: 5m
   - name: user-satisfaction
     thresholdRange:
       min: 4.0
     interval: 10m
   ```

### Load Testing Integration

5. **K6 Load Testing**
   ```yaml
   webhooks:
   - name: load-test
     url: http://k6-operator.k6-operator.svc:8080/load-test
     timeout: 5s
     metadata:
       type: cmd
       cmd: "k6 run --out influxdb=http://prometheus-operated.prometheus.svc:9090 /scripts/load-test.js"
   ```

## 🔧 Implementation Steps

### Phase 1: Infrastructure Setup ✅

- [x] **Flagger Installation**: Helm chart with Istio integration
- [x] **Istio Gateway**: Traffic management configuration
- [x] **Prometheus Integration**: Metrics collection setup
- [x] **Namespace Configuration**: Resource isolation

### Phase 2: Application Configuration ✅

- [x] **Bruno Site Helm Release**: Application deployment
- [x] **Istio Resources**: VirtualService and DestinationRule
- [x] **Canary Configuration**: Progressive delivery setup
- [x] **Traffic Routing**: Service mesh configuration

### Phase 3: Advanced Features 🚧

- [ ] **A/B Testing**: Traffic splitting implementation
- [ ] **Custom Metrics**: Business KPIs integration
- [ ] **Automated Rollback**: Failure detection and recovery
- [ ] **Performance Testing**: Load testing automation

### Phase 4: Monitoring & Observability 🚧

- [ ] **Grafana Dashboards**: Deployment metrics visualization
- [ ] **Alerting**: Automated notifications for failures
- [ ] **Logging**: Centralized log aggregation
- [ ] **Tracing**: Distributed tracing with Tempo

## 🎯 Traffic Management

### Istio Virtual Service

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bruno-site-vs
  namespace: bruno
spec:
  hosts:
  - "bruno.dev.local"
  - "*.bruno.dev.local"
  
  gateways:
  - flagger-gateway
  
  http:
  # Primary route (stable)
  - name: primary
    match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: bruno-site-primary
        port:
          number: 8080
      weight: 100
  
  # Canary route (testing)
  - name: canary
    match:
    - uri:
        prefix: "/canary"
    route:
    - destination:
        host: bruno-site-canary
        port:
          number: 8080
      weight: 100
```

### Destination Rules

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: bruno-site-dr
  namespace: bruno
spec:
  host: bruno-site
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    
    connectionPool:
      tcp:
        maxConnections: 100
        connectTimeout: 30ms
      http:
        http1MaxPendingRequests: 1024
        maxRequestsPerConnection: 10
        maxRetries: 3
```

## 📈 Monitoring & Alerting

### Prometheus Metrics

1. **Flagger Metrics**
   - `flagger_canary_total`
   - `flagger_canary_status`
   - `flagger_canary_duration_seconds`

2. **Application Metrics**
   - `http_requests_total`
   - `http_request_duration_seconds`
   - `http_errors_total`

3. **Business Metrics**
   - `conversion_rate`
   - `user_satisfaction_score`
   - `feature_usage_count`

### Grafana Dashboards

1. **Deployment Overview**
   - Canary status and progress
   - Traffic distribution
   - Success/failure rates

2. **Performance Metrics**
   - Response times
   - Error rates
   - Throughput

3. **Business KPIs**
   - Conversion rates
   - User engagement
   - Feature adoption

## 🔄 GitOps Workflow

### Deployment Process

1. **Code Changes**: Push to main branch
2. **Image Build**: GitHub Actions builds new container
3. **Flux Sync**: Automatically detects changes
4. **Canary Start**: Flagger initiates progressive deployment
5. **Traffic Shift**: Gradual traffic migration
6. **Analysis**: Metrics-based success evaluation
7. **Promotion**: Automatic or manual promotion
8. **Cleanup**: Old versions removal

### Rollback Process

1. **Failure Detection**: Metrics below thresholds
2. **Automatic Rollback**: Traffic returns to stable version
3. **Investigation**: Root cause analysis
4. **Fix Implementation**: Code changes and testing
5. **Redeployment**: New canary deployment

## 🛠️ Configuration Management

### Environment Variables

```bash
# Flagger Configuration
export FLAGGER_NAMESPACE="flagger-system"
export FLAGGER_PROMETHEUS_URL="http://prometheus-operated.prometheus.svc:9090"
export FLAGGER_GRAFANA_URL="http://grafana.grafana.svc:80"

# Application Configuration
export BRUNO_SITE_NAMESPACE="bruno"
export BRUNO_SITE_IMAGE="ghcr.io/brunovlucena/bruno-site:dev"
export BRUNO_SITE_REPLICAS="2"
```

### Helm Values

```yaml
# Flagger Helm Values
flagger:
  meshProvider: istio
  metricsServer: http://prometheus-operated.prometheus.svc:9090
  
  istio:
    enabled: true
    gateway:
      enabled: true
      name: flagger-gateway
      namespace: flagger-system
  
  prometheus:
    enabled: true
    service:
      port: 9090
      targetPort: 9090
  
  grafana:
    enabled: true
    host: http://grafana.grafana.svc:80
```

## 🧪 Testing Strategy

### Load Testing

1. **K6 Integration**: Automated performance testing
2. **Traffic Simulation**: Realistic user behavior
3. **Stress Testing**: Breaking point identification
4. **Regression Testing**: Performance comparison

### Chaos Testing

1. **Pod Failure**: Random pod termination
2. **Network Issues**: Latency and packet loss
3. **Resource Constraints**: CPU and memory limits
4. **Service Dependencies**: Database and external service failures

## 🔒 Security Considerations

### Network Security

1. **Istio mTLS**: Service-to-service encryption
2. **Network Policies**: Pod-to-pod communication control
3. **Ingress Security**: TLS termination and authentication
4. **Egress Control**: Outbound traffic restrictions

### Access Control

1. **RBAC**: Role-based access control
2. **Service Accounts**: Minimal privilege principle
3. **Secrets Management**: Secure credential storage
4. **Audit Logging**: Access and change tracking

## 📊 Success Metrics

### Technical Metrics

- **Deployment Success Rate**: >95%
- **Rollback Time**: <2 minutes
- **Zero Downtime**: 100% uptime during deployments
- **Performance Impact**: <5% degradation during canary

### Business Metrics

- **Feature Adoption**: Measurable increase in usage
- **User Satisfaction**: Improved satisfaction scores
- **Conversion Rates**: Higher conversion percentages
- **Error Reduction**: Decreased error rates

## 🚧 Future Enhancements

### Advanced Features

1. **Multi-Cluster Deployment**: Cross-cluster canary deployments
2. **Feature Flags**: Dynamic feature toggling
3. **Machine Learning**: AI-powered rollback decisions
4. **Cost Optimization**: Resource usage optimization

### Integration

1. **Slack Notifications**: Deployment status updates
2. **Jira Integration**: Issue tracking and management
3. **Datadog Integration**: Enhanced monitoring
4. **PagerDuty**: Incident management

## 🔍 Troubleshooting

### Common Issues

1. **Canary Stuck**
   ```bash
   # Check Flagger logs
   kubectl logs -n flagger-system -l app=flagger
   
   # Force reconciliation
   kubectl annotate canary/bruno-site -n bruno flagger.fluxcd.io/trigger=now
   ```

2. **Traffic Not Shifting**
   ```bash
   # Check Istio resources
   kubectl get virtualservice -n bruno
   kubectl get destinationrule -n bruno
   
   # Verify gateway configuration
   kubectl get gateway -n flagger-system
   ```

3. **Metrics Not Available**
   ```bash
   # Check Prometheus connectivity
   kubectl port-forward -n prometheus svc/prometheus-operated 9090:9090
   
   # Verify Flagger metrics
   curl http://localhost:9090/api/v1/query?query=flagger_canary_total
   ```

### Debug Commands

```bash
# Check Flagger status
kubectl get canary -n bruno

# View canary details
kubectl describe canary bruno-site -n bruno

# Check Istio resources
kubectl get virtualservice,destinationrule -n bruno

# Monitor canary progress
kubectl logs -n flagger-system -l app=flagger -f

# Force canary trigger
kubectl annotate canary/bruno-site -n bruno flagger.fluxcd.io/trigger=now
```

## 📚 Resources & References

### Documentation

- [Flagger Documentation](https://docs.flagger.app/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Flux GitOps Toolkit](https://fluxcd.io/docs/)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)

### Examples

- [Flagger Canary Examples](https://github.com/fluxcd/flagger/tree/main/examples)
- [Istio Virtual Service Examples](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
- [Flux Helm Release Examples](https://fluxcd.io/docs/components/helm/helmreleases/)

---

**🎯 Goal**: Implement robust progressive delivery for Bruno Site with automated rollback, A/B testing, and comprehensive monitoring.

**📅 Timeline**: Phase 1-2 complete, Phase 3-4 in progress

**🔄 Status**: Active development with canary deployments enabled
