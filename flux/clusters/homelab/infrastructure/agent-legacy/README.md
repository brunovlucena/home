# Agent Legacy for Kubernetes

A modern AI agent using LangGraph that connects to Ollama for intelligent log analysis and system monitoring.

## 🚀 Features

- **LangGraph Framework**: Graph-based AI agent architecture
- **Ollama Integration**: Local model inference with Gemma 3n:e4b
- **Loki Integration**: Direct log querying and analysis
- **Kubernetes Native**: Full K8s deployment with HPA, monitoring, and ingress
- **FastAPI**: Modern async API with health checks and metrics
- **Production Ready**: Security, resource limits, and observability

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Agent Legacy  │───▶│   Ollama LLM     │───▶│   Loki Logs     │
│   (LangGraph)   │    │   (Local Model)   │    │   (Analysis)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   FastAPI      │    │   Kubernetes     │    │   Prometheus    │
│   (REST API)    │    │   (Deployment)    │    │   (Monitoring)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🛠️ Components

### **Agent Capabilities**
- **Log Analysis**: Query and analyze Loki logs
- **Test Monitoring**: Monitor test failures and success rates
- **System Health**: Check overall system status
- **Intelligent Responses**: AI-powered insights and recommendations

### **Kubernetes Resources**
- **Namespace**: `agent-legacy`
- **Deployment**: 2 replicas with auto-scaling
- **Service**: ClusterIP for internal communication
- **Ingress**: External access via `agent-legacy.homelab.local`
- **HPA**: Auto-scaling based on CPU/memory usage
- **ServiceMonitor**: Prometheus metrics collection

## 🚀 Deployment

### **Prerequisites**
- Kubernetes cluster with Flux
- Ollama service running
- Loki instance available
- Prometheus for monitoring

### **Deploy the Agent**
```bash
# Apply all resources
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f servicemonitor.yaml
kubectl apply -f hpa.yaml
```

### **Build and Push Docker Image**
```bash
# Build the image
docker build -t agent-legacy:latest .

# Tag for your registry
docker tag agent-legacy:latest your-registry/agent-legacy:latest

# Push to registry
docker push your-registry/agent-legacy:latest
```

## 📡 API Endpoints

### **Health & Metrics**
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

### **Agent Endpoints**
- `POST /chat` - Main chat interface
- `POST /analyze-logs` - Direct log analysis
- `POST /test-analysis` - Test failure analysis
- `POST /system-health` - System health check

### **Example Usage**
```bash
# Chat with the agent
curl -X POST http://agent-legacy.homelab.local/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze the test failures from the last hour"}'

# Direct log analysis
curl -X POST http://agent-legacy.homelab.local/analyze-logs \
  -H "Content-Type: application/json" \
  -d '{"query": "{namespace=\"mocks\"} |= \"error\"}"}'

# Test analysis
curl -X POST http://agent-legacy.homelab.local/test-analysis

# System health
curl -X POST http://agent-legacy.homelab.local/system-health
```

## 🔧 Configuration

### **Environment Variables**
- `OLLAMA_URL`: Ollama service URL (default: `http://ollama-service:11434`)
- `MODEL_NAME`: Model to use (default: `gemma3n:e4b`)
- `LOKI_URL`: Loki service URL (default: `http://loki-write.loki:3100`)
- `AGENT_PORT`: Agent service port (default: `8080`)
- `LOG_LEVEL`: Logging level (default: `info`)

### **Resource Limits**
- **Requests**: 512Mi memory, 200m CPU
- **Limits**: 2Gi memory, 1000m CPU
- **HPA**: 2-10 replicas based on CPU/memory usage

## 📊 Monitoring

### **Prometheus Metrics**
- `agent_requests_total`: Total requests processed
- `agent_errors_total`: Total errors encountered
- `ollama_connection`: Ollama connection status

### **Health Checks**
- **Liveness**: HTTP GET `/health` every 30s
- **Readiness**: HTTP GET `/health` every 10s
- **Startup**: 60s initial delay

## 🔒 Security

### **Security Context**
- Non-root user (UID 1000)
- Dropped capabilities
- No privilege escalation
- Read-only root filesystem

### **Network Policies**
- Internal cluster communication only
- Ingress via NGINX controller
- No external egress required

## 🎯 Use Cases

### **Log Analysis**
- Query Loki logs with natural language
- Analyze error patterns and trends
- Generate insights and recommendations

### **Test Monitoring**
- Monitor test execution and failures
- Identify flaky tests and patterns
- Provide test health summaries

### **System Health**
- Check overall system status
- Identify potential issues
- Provide proactive recommendations

## 🚀 Advanced Features

### **LangGraph Workflow**
- Graph-based agent reasoning
- Tool integration for log analysis
- State management and context
- Error handling and recovery

### **Auto-scaling**
- CPU-based scaling (70% threshold)
- Memory-based scaling (80% threshold)
- Scale-down stabilization (5 minutes)
- Scale-up stabilization (1 minute)

### **Observability**
- Structured logging
- Prometheus metrics
- Health checks
- Distributed tracing ready

## 🔧 Troubleshooting

### **Common Issues**
1. **Ollama Connection**: Check `OLLAMA_URL` and service availability
2. **Loki Access**: Verify `LOKI_URL` and network connectivity
3. **Resource Limits**: Monitor CPU/memory usage
4. **Image Pull**: Ensure Docker image is available

### **Debug Commands**
```bash
# Check pod status
kubectl get pods -n agent-legacy

# View logs
kubectl logs -n agent-legacy -l app.kubernetes.io/name=agent-legacy

# Check service
kubectl get svc -n agent-legacy

# Test connectivity
kubectl exec -n agent-legacy deployment/agent-legacy -- curl http://localhost:8080/health
```

## 📚 References

- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [Ollama Kubernetes Guide](https://github.com/ollama/ollama/blob/main/examples/kubernetes/README.md)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

---

**Built with ❤️ for modern AI infrastructure**
