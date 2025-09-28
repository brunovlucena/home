# SRE Agent MCP Server Makefile

.PHONY: build build-push deploy test clean logs status

# Default target
help:
	@echo "Available targets:"
	@echo "  build     - Build Docker image"
	@echo "  build-push - Build and push Docker image to registry"
	@echo "  deploy    - Deploy to Kubernetes"
	@echo "  test      - Test the deployed service"
	@echo "  logs      - Show pod logs"
	@echo "  status    - Show deployment status"
	@echo "  clean     - Clean up deployment"
	@echo "  help      - Show this help message"

# Build Docker image
build:
	@echo "🔨 Building SRE Agent MCP Docker image..."
	docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/brunovlucena/agent-sre:latest .

# Build and push Docker image to registry
build-push:
	@echo "📦 Building and pushing SRE Agent MCP Docker image to registry..."
	docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/brunovlucena/agent-sre:latest --push .
	@echo "✅ Image built and pushed successfully"

# Test the deployed service
test:
	@echo "🧪 Testing deployed service..."
	@echo "Health check:"
	curl -s http://localhost:31120/health | jq .
	@echo ""
	@echo "MCP endpoint test:"
	curl -s -X POST "http://localhost:31120/mcp/?sreApiKey=sre-dev-your-key" \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}' | jq .

# Show pod logs
logs:
	@echo "📝 Showing pod logs..."
	kubectl logs -l app=sre-agent-mcp --tail=50 -f -n agent-sre

# Show deployment status
status:
	@echo "📊 Deployment status:"
	kubectl get pods -l app=sre-agent-mcp -n agent-sre
	@echo ""
	@echo "🌐 Service status:"
	kubectl get service sre-agent-mcp-service -n agent-sre
	@echo ""
	@echo "📋 Service endpoints:"
	kubectl get endpoints sre-agent-mcp-service -n agent-sre

# Clean up deployment
clean:
	@echo "🧹 Cleaning up deployment..."
	kubectl delete -f k8s-deployment.yaml
	@echo "✅ Cleanup complete"