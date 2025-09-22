# Jamie SRE Chatbot - Logfire Prometheus Metrics

This document describes how the Jamie SRE Chatbot leverages Logfire's built-in OpenTelemetry capabilities to export metrics to Prometheus for monitoring and alerting.

## 🔧 Overview

The jamie-sre-chatbot uses **Logfire's built-in OpenTelemetry metrics** (no duplicate implementation needed). Logfire automatically handles OpenTelemetry instrumentation and can export metrics to Prometheus, providing both rich observability and standard monitoring metrics.

## 📊 Metrics Architecture

### 1. **Unified Observability Stack**
- **Logfire**: Structured logging, distributed tracing, and custom metrics (built on OpenTelemetry)
- **Prometheus Export**: Logfire's metrics automatically exported to Prometheus format

### 2. **Metrics Endpoints**
- **Port 8080**: Main API server with `/health` and `/chat` endpoints
- **Port 9090**: Dedicated metrics server with `/metrics` endpoint for Prometheus scraping

## 🎯 Available Metrics

### **Ollama AI Model Metrics**
```prometheus
# Counter: Total Ollama requests
ollama_requests_total{model="bruno-sre", status="success"}

# Histogram: Request duration in seconds
ollama_request_duration_seconds_bucket{model="bruno-sre", le="0.1"}
ollama_request_duration_seconds_sum{model="bruno-sre"}
ollama_request_duration_seconds_count{model="bruno-sre"}

# Counter: Total Ollama errors
ollama_errors_total{model="bruno-sre", error_type="RequestException"}
```

### **Slack Integration Metrics**
```prometheus
# Counter: Total Slack mentions
slack_mentions_total{status="success"}

# Counter: Total slash commands
slack_slash_commands_total{status="success"}

# Counter: Total direct messages
slack_direct_messages_total{status="success"}
```

### **API Metrics**
```prometheus
# Counter: Total API chat requests
api_chat_requests_total{status="success"}

# Histogram: API request duration
api_chat_request_duration_seconds_bucket{le="0.1"}
api_chat_request_duration_seconds_sum
api_chat_request_duration_seconds_count
```

### **Flask Instrumentation Metrics** (Auto-generated)
```prometheus
# HTTP request metrics
http_requests_total{method="GET", route="/health", status="200"}
http_requests_total{method="GET", route="/metrics", status="200"}
http_requests_total{method="POST", route="/chat", status="200"}

# HTTP request duration
http_request_duration_seconds_bucket{method="GET", route="/health", le="0.1"}
http_request_duration_seconds_sum{method="GET", route="/health"}
http_request_duration_seconds_count{method="GET", route="/health"}
```

## 🚀 Setup Instructions

### 1. **Dependencies Added**
Only one additional dependency needed for Prometheus export:

```toml
"prometheus-client>=0.19.0"
```

**Why so simple?** Logfire already includes OpenTelemetry under the hood, so we don't need to duplicate the instrumentation.

### 2. **Kubernetes Configuration**

#### **Deployment Updates**
- Added metrics port 9090 to container ports
- Both API (8080) and metrics (9090) ports are exposed

#### **Service Configuration**
- Port 8080: HTTP API traffic
- Port 9090: Prometheus metrics scraping

#### **ServiceMonitor**
- **File**: `k8s/servicemonitor.yaml`
- **Scraping**: Every 30 seconds
- **Path**: `/metrics`
- **Port**: `metrics` (9090)
- **Metric Filtering**: Only jamie-sre-chatbot metrics

### 3. **Environment Variables**
No additional environment variables required. Logfire handles the OpenTelemetry setup automatically when configured with a token.

## 📈 Monitoring Dashboard

### **Key Metrics to Monitor**

#### 1. **Response Times**
```promql
# Ollama response time (95th percentile)
histogram_quantile(0.95, rate(ollama_request_duration_seconds_bucket[5m]))

# API response time (95th percentile)  
histogram_quantile(0.95, rate(api_chat_request_duration_seconds_bucket[5m]))
```

#### 2. **Error Rates**
```promql
# Ollama error rate
rate(ollama_errors_total[5m]) / rate(ollama_requests_total[5m])

# API error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

#### 3. **Request Rates**
```promql
# Ollama request rate
rate(ollama_requests_total[5m])

# Slack interaction rate
rate(slack_mentions_total[5m]) + rate(slack_slash_commands_total[5m]) + rate(slack_direct_messages_total[5m])

# API request rate
rate(api_chat_requests_total[5m])
```

#### 4. **System Health**
```promql
# Service availability
up{job="jamie-sre-chatbot"}

# Health check endpoint
http_requests_total{route="/health", status="200"}
```

### **Alerting Rules**

#### 1. **High Error Rate**
```yaml
- alert: JamieHighErrorRate
  expr: rate(ollama_errors_total[5m]) / rate(ollama_requests_total[5m]) > 0.1
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Jamie SRE Chatbot high error rate"
    description: "Error rate is {{ $value | humanizePercentage }}"
```

#### 2. **Slow Responses**
```yaml
- alert: JamieSlowResponses
  expr: histogram_quantile(0.95, rate(ollama_request_duration_seconds_bucket[5m])) > 5
  for: 3m
  labels:
    severity: warning
  annotations:
    summary: "Jamie SRE Chatbot slow responses"
    description: "95th percentile response time is {{ $value }}s"
```

#### 3. **Service Down**
```yaml
- alert: JamieServiceDown
  expr: up{job="jamie-sre-chatbot"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Jamie SRE Chatbot is down"
    description: "Service has been down for more than 1 minute"
```

## 🔍 Testing Metrics

### **Local Testing**
```bash
# Check metrics endpoint
curl http://localhost:9090/metrics

# Check health endpoint
curl http://localhost:9090/health

# Test API endpoint
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello Jamie"}'
```

### **Kubernetes Testing**
```bash
# Port forward to test metrics
kubectl port-forward -n chatbots svc/jamie-sre-chatbot 9090:9090

# Check metrics
curl http://localhost:9090/metrics

# Check ServiceMonitor
kubectl get servicemonitor -n chatbots jamie-sre-chatbot
```

## 🛠️ Troubleshooting

### **Common Issues**

#### 1. **Metrics Not Available**
- Check if OpenTelemetry dependencies are installed
- Verify metrics server is running on port 9090
- Check logs for OpenTelemetry initialization errors

#### 2. **Prometheus Not Scraping**
- Verify ServiceMonitor is created: `kubectl get servicemonitor -n chatbots`
- Check Prometheus targets: Look for `jamie-sre-chatbot` in Prometheus UI
- Verify service has correct labels for ServiceMonitor selector

#### 3. **Missing Metrics**
- Check if metrics are being recorded in application logs
- Verify OpenTelemetry meter provider is initialized
- Test metrics endpoint manually: `curl http://pod-ip:9090/metrics`

### **Debug Commands**
```bash
# Check pod logs
kubectl logs -n chatbots deployment/jamie-sre-chatbot

# Check service endpoints
kubectl get endpoints -n chatbots jamie-sre-chatbot

# Check ServiceMonitor
kubectl describe servicemonitor -n chatbots jamie-sre-chatbot

# Test metrics from within cluster
kubectl run test-pod --image=curlimages/curl -it --rm -- curl http://jamie-sre-chatbot.chatbots.svc.cluster.local:9090/metrics
```

## 📚 Integration with Existing Stack

### **Logfire + Prometheus**
- **Logfire**: Rich structured logs, distributed tracing, custom metrics
- **Prometheus**: Standard metrics for monitoring, alerting, and dashboards
- **Both systems work together** without conflicts

### **Grafana Dashboard**
Create a Grafana dashboard using the Prometheus metrics:

```json
{
  "dashboard": {
    "title": "Jamie SRE Chatbot",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(ollama_requests_total[5m])",
            "legendFormat": "Ollama Requests/sec"
          }
        ]
      },
      {
        "title": "Response Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(ollama_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
```

## 🎯 Benefits

1. **No Duplication**: Leverages Logfire's built-in OpenTelemetry instead of duplicating instrumentation
2. **Standard Metrics**: Prometheus-compatible metrics for existing monitoring stack
3. **Unified Observability**: Single source of truth for both Logfire and Prometheus metrics
4. **Auto-instrumentation**: Flask and Requests automatically instrumented by Logfire
5. **Custom Metrics**: Application-specific metrics for business logic
6. **Easy Integration**: Works with existing Prometheus/Grafana setup
7. **Performance**: Minimal overhead with efficient metric collection
8. **Maintainability**: Less code to maintain, fewer dependencies

---

*This approach leverages Logfire's built-in OpenTelemetry capabilities to provide comprehensive metrics for the Jamie SRE Chatbot without duplicating instrumentation.*
