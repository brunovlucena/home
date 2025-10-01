# 🚀 SRE Agent Refactored - Separate MCP Server and Agent Deployments

## 🎯 Overview

This project has been refactored to separate the MCP server and agent into two independent deployments, providing better scalability, maintainability, and deployment flexibility.

## 🏗️ Architecture

### Before (Monolithic)
```
┌─────────────────────────────────────┐
│         Single Deployment           │
│  ┌─────────────────────────────────┐ │
│  │  SRE Agent + MCP Server         │ │
│  │  (Combined in one container)    │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### After (Microservices)
```
┌─────────────────────┐    ┌─────────────────────┐
│   MCP Server        │    │   SRE Agent         │
│  ┌─────────────────┐│    │  ┌─────────────────┐│
│  │  MCP Protocol   ││    │  │  HTTP API       ││
│  │  Tool Execution ││◄───┤  │  MCP Client     ││
│  │  Health Checks  ││    │  │  Direct Agent   ││
│  └─────────────────┘│    │  └─────────────────┘│
└─────────────────────┘    └─────────────────────┘
```

## 📁 Project Structure

```
agent-sre-refactor/
├── deployments/
│   ├── mcp-server/              # MCP Server deployment
│   │   ├── Dockerfile          # MCP Server container
│   │   ├── mcp_server.py       # MCP Server implementation
│   │   └── k8s-mcp-server.yaml # Kubernetes manifests
│   └── agent/                   # Agent deployment
│       ├── Dockerfile          # Agent container
│       ├── agent.py            # Agent implementation
│       └── k8s-agent.yaml      # Kubernetes manifests
├── docker-compose.yml          # Local development
├── nginx.conf                  # Reverse proxy config
├── Makefile.refactored         # Build and deploy commands
└── README.refactored.md        # This file
```

## 🚀 Quick Start

### 1. Local Development with Docker Compose

```bash
# Start both services
make -f Makefile.refactored start

# Check health
make -f Makefile.refactored health

# View logs
make -f Makefile.refactored logs

# Stop services
make -f Makefile.refactored stop
```

### 2. Kubernetes Deployment

```bash
# Deploy MCP Server
make -f Makefile.refactored deploy-mcp

# Deploy Agent
make -f Makefile.refactored deploy-agent

# Or deploy both
make -f Makefile.refactored deploy-all
```

## 🔧 Services

### MCP Server (Port 30120)

**Purpose**: Handles MCP protocol communication and tool execution

**Endpoints**:
- `GET /health` - Health check
- `GET /ready` - Readiness check
- `POST /mcp` - MCP protocol endpoint
- `GET /sse` - Server-Sent Events

**Tools Available**:
- `sre_chat` - General SRE consultation
- `analyze_logs` - Log analysis
- `incident_response` - Incident response guidance
- `monitoring_advice` - Monitoring recommendations
- `health_check` - Health status

### SRE Agent (Port 8080)

**Purpose**: HTTP API service that can communicate with MCP server or work directly

**Endpoints**:
- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /status` - Service status
- `POST /chat` - Direct chat (local agent)
- `POST /analyze-logs` - Direct log analysis
- `POST /mcp/chat` - Chat via MCP server
- `POST /mcp/analyze-logs` - Log analysis via MCP server

## 🧪 Testing

### Test MCP Communication
```bash
# Test MCP chat
curl -X POST http://localhost:8080/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "How do I monitor Kubernetes pods?"}'

# Test MCP log analysis
curl -X POST http://localhost:8080/mcp/analyze-logs \
  -H "Content-Type: application/json" \
  -d '{"logs": "ERROR: Database connection failed"}'
```

### Test Direct Agent Communication
```bash
# Test direct chat
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "How do I monitor Kubernetes pods?"}'

# Test direct log analysis
curl -X POST http://localhost:8080/analyze-logs \
  -H "Content-Type: application/json" \
  -d '{"logs": "ERROR: Database connection failed"}'
```

## 📊 Monitoring

### Health Checks
```bash
# Check MCP Server health
curl http://localhost:30120/health

# Check Agent health
curl http://localhost:8080/health

# Check Agent status (includes MCP server status)
curl http://localhost:8080/status
```

### Service URLs
- **MCP Server**: http://localhost:30120
- **Agent**: http://localhost:8080
- **Nginx Proxy**: http://localhost:80

## 🔄 Deployment Options

### Option 1: Direct Communication
The agent can work independently without the MCP server:
- Use `/chat`, `/analyze-logs`, etc. endpoints
- Direct communication with Ollama
- No MCP protocol overhead

### Option 2: MCP Communication
The agent communicates with the MCP server:
- Use `/mcp/chat`, `/mcp/analyze-logs`, etc. endpoints
- MCP protocol communication
- Tool execution via MCP server

### Option 3: Hybrid
Use both approaches based on requirements:
- Direct for simple queries
- MCP for complex tool execution

## 🚀 Scaling

### Horizontal Scaling
```bash
# Scale MCP Server
kubectl scale deployment sre-agent-mcp-server --replicas=3 -n agent-sre

# Scale Agent
kubectl scale deployment sre-agent --replicas=3 -n agent-sre
```

### Load Balancing
The services are designed to work with load balancers:
- MCP Server: Multiple replicas with load balancing
- Agent: Multiple replicas with load balancing
- Nginx: Reverse proxy for external access

## 🔧 Configuration

### Environment Variables

**MCP Server**:
- `MCP_PORT` - Server port (default: 30120)
- `MCP_HOST` - Server host (default: 0.0.0.0)
- `OLLAMA_URL` - Ollama server URL
- `MODEL_NAME` - Model name to use

**Agent**:
- `AGENT_PORT` - Agent port (default: 8080)
- `AGENT_HOST` - Agent host (default: 0.0.0.0)
- `MCP_SERVER_URL` - MCP server URL
- `OLLAMA_URL` - Ollama server URL
- `MODEL_NAME` - Model name to use

## 🛠️ Development

### Building Images
```bash
# Build MCP Server
make -f Makefile.refactored build-mcp

# Build Agent
make -f Makefile.refactored build-agent

# Build both
make -f Makefile.refactored build-all
```

### Pushing Images
```bash
# Push MCP Server
make -f Makefile.refactored push-mcp

# Push Agent
make -f Makefile.refactored push-agent

# Push both
make -f Makefile.refactored push-all
```

## 🔍 Troubleshooting

### Check Service Status
```bash
# Check MCP Server
curl http://localhost:30120/ready

# Check Agent
curl http://localhost:8080/ready

# Check MCP Server from Agent
curl http://localhost:8080/mcp/status
```

### View Logs
```bash
# Docker Compose logs
docker-compose logs -f

# Kubernetes logs
kubectl logs -f deployment/sre-agent-mcp-server -n agent-sre
kubectl logs -f deployment/sre-agent -n agent-sre
```

## 🎯 Benefits of Refactored Architecture

1. **Separation of Concerns**: MCP server handles protocol, agent handles business logic
2. **Independent Scaling**: Scale MCP server and agent independently
3. **Deployment Flexibility**: Deploy services separately or together
4. **Fault Isolation**: Issues in one service don't affect the other
5. **Development Efficiency**: Work on MCP server and agent independently
6. **Testing**: Test MCP server and agent separately
7. **Maintenance**: Update and maintain services independently

## 🔄 Migration from Monolithic

The refactored architecture maintains backward compatibility:
- Same API endpoints
- Same functionality
- Same configuration options
- Additional MCP-specific endpoints

## 📈 Performance

### MCP Server
- Optimized for MCP protocol handling
- Efficient tool execution
- Minimal overhead

### Agent
- Direct Ollama communication
- HTTP API optimization
- MCP client efficiency

## 🔒 Security

- Non-root containers
- Network isolation
- Secret management
- Health checks and probes
- Resource limits

## 📚 Documentation

- [MCP Server API](./deployments/mcp-server/README.md)
- [Agent API](./deployments/agent/README.md)
- [Kubernetes Manifests](./k8s/README.md)
- [Docker Compose](./docker-compose.yml)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test both services
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
