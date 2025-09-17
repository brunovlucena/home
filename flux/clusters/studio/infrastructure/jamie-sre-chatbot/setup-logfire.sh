#!/bin/bash
# Setup script for Jamie SRE Chatbot with Logfire instrumentation

set -e

echo "🔥 Setting up Jamie SRE Chatbot with Logfire instrumentation..."

# Check if LOGFIRE_TOKEN is provided
if [ -z "$LOGFIRE_TOKEN" ]; then
    echo "❌ Error: LOGFIRE_TOKEN environment variable is required"
    echo "   Get your token from: https://logfire.pydantic.dev/dashboard"
    echo "   Then run: export LOGFIRE_TOKEN='your-token-here'"
    exit 1
fi

echo "✅ LOGFIRE_TOKEN found"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is required but not installed"
    exit 1
fi

echo "✅ kubectl found"

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Not connected to a Kubernetes cluster"
    echo "   Please connect to your cluster first"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
kubectl create namespace chatbots --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Namespace 'chatbots' ready"

# Encode the Logfire token
LOGFIRE_TOKEN_B64=$(echo -n "$LOGFIRE_TOKEN" | base64)

echo "✅ Logfire token encoded"

# Update the secrets file with the encoded token
if [ -f "k8s/secrets.yaml" ]; then
    # Create a temporary file with the updated token
    sed "s/LOGFIRE_TOKEN: \"\"/LOGFIRE_TOKEN: \"$LOGFIRE_TOKEN_B64\"/" k8s/secrets.yaml > k8s/secrets-temp.yaml
    mv k8s/secrets-temp.yaml k8s/secrets.yaml
    echo "✅ Updated secrets.yaml with Logfire token"
else
    echo "❌ Error: k8s/secrets.yaml not found"
    exit 1
fi

# Apply the Kubernetes manifests
echo "🚀 Applying Kubernetes manifests..."

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployment.yaml

echo "✅ Kubernetes manifests applied"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/jamie-sre-chatbot -n chatbots

echo "✅ Deployment is ready!"

# Show the status
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n chatbots -l app=jamie-sre-chatbot

echo ""
echo "📝 Logs (last 20 lines):"
kubectl logs -n chatbots -l app=jamie-sre-chatbot --tail=20

echo ""
echo "🎉 Jamie SRE Chatbot with Logfire instrumentation is ready!"
echo ""
echo "📈 To view Logfire metrics and logs:"
echo "   1. Visit: https://logfire.pydantic.dev/dashboard"
echo "   2. Look for service: 'jamie-sre-chatbot'"
echo "   3. Monitor metrics and traces in real-time"
echo ""
echo "🔍 To debug issues:"
echo "   kubectl logs -n chatbots -l app=jamie-sre-chatbot -f"
echo ""
echo "🛠️  To update the Logfire token:"
echo "   export LOGFIRE_TOKEN='new-token'"
echo "   ./setup-logfire.sh"
