#!/bin/bash

# =============================================================================
# 🔧 SETUP MCP SERVERS FOR GRAFANA AND PROMETHEUS
# =============================================================================
# This script sets up MCP servers for Grafana and Prometheus integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_status "Setting up MCP servers for Grafana and Prometheus"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Wait for Grafana to be ready
print_status "Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-operator-grafana -n prometheus

# Get Grafana admin password
print_status "Getting Grafana admin password..."
GRAFANA_PASSWORD=$(kubectl get secret prometheus-operator-grafana -n prometheus -o jsonpath='{.data.admin-password}' | base64 -d)

# Create Grafana API key
print_status "Creating Grafana API key..."
GRAFANA_API_KEY=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"mcp-server-key","role":"Admin"}' \
  -u "admin:${GRAFANA_PASSWORD}" \
  http://localhost:3000/api/auth/keys 2>/dev/null | jq -r '.key' || echo "manual-setup-required")

if [ "$GRAFANA_API_KEY" = "manual-setup-required" ]; then
    print_warning "Could not automatically create API key. Please create one manually:"
    echo "1. Go to Grafana: http://localhost:3000"
    echo "2. Login with admin/${GRAFANA_PASSWORD}"
    echo "3. Go to Administration > API Keys"
    echo "4. Create a new API key with Admin role"
    echo "5. Update the secret with: kubectl patch secret grafana-mcp-secrets -n prometheus --type='json' -p='[{\"op\": \"replace\", \"path\": \"/data/api-key\", \"value\": \"'$(echo -n 'YOUR_API_KEY' | base64)'\"}]'"
else
    print_success "Grafana API key created successfully"
fi

# Apply MCP server deployments
print_status "Deploying Grafana MCP server..."
kubectl apply -f grafana-mcp-server.yaml

print_status "Deploying Prometheus MCP server..."
kubectl apply -f prometheus-mcp-server.yaml

# Wait for deployments to be ready
print_status "Waiting for MCP servers to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana-mcp-server -n prometheus
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-mcp-server -n prometheus

print_success "MCP servers deployed successfully!"

print_status "MCP Server Endpoints:"
echo "  Grafana MCP Server: http://grafana-mcp-server.prometheus.svc.cluster.local:8080"
echo "  Prometheus MCP Server: http://prometheus-mcp-server.prometheus.svc.cluster.local:8080"

print_status "To access from outside the cluster, use port-forward:"
echo "  kubectl port-forward -n prometheus svc/grafana-mcp-server 8081:8080"
echo "  kubectl port-forward -n prometheus svc/prometheus-mcp-server 8082:8080"

print_warning "Note: Make sure to update the Grafana API key in the secret if manual setup was required"
