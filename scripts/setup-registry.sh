#!/bin/bash

# Simple script to setup local Docker registry for existing Kind cluster
# This script only handles the registry setup and network connection

set -e

REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5000"
KIND_CLUSTER_NAME="homelab"

echo "🚀 Setting up local Docker registry for Kind cluster: $KIND_CLUSTER_NAME"

# Stop and remove existing registry if it exists
echo "🧹 Cleaning up existing registry..."
docker stop $REGISTRY_NAME 2>/dev/null || true
docker rm $REGISTRY_NAME 2>/dev/null || true

# Create local registry
echo "📦 Creating local Docker registry..."
docker run -d \
  --name $REGISTRY_NAME \
  --restart=always \
  -p $REGISTRY_PORT:5000 \
  registry:2

# Wait for registry to be ready
echo "⏳ Waiting for registry to be ready..."
sleep 3

# Check if registry is running
if ! docker ps | grep -q $REGISTRY_NAME; then
    echo "❌ Failed to start registry"
    exit 1
fi

echo "✅ Local registry is running at localhost:$REGISTRY_PORT"

# Connect registry to kind network
echo "🔗 Connecting registry to Kind network..."
docker network connect kind $REGISTRY_NAME 2>/dev/null || true

echo ""
echo "🎉 Registry setup complete!"
echo ""
echo "📋 Usage:"
echo "1. Build and tag: docker build -t localhost:$REGISTRY_PORT/my-app:latest ."
echo "2. Push: docker push localhost:$REGISTRY_PORT/my-app:latest"
echo "3. Deploy: kubectl create deployment my-app --image=localhost:$REGISTRY_PORT/my-app:latest"
echo ""
echo "🔧 Management:"
echo "   Stop: docker stop $REGISTRY_NAME"
echo "   Start: docker start $REGISTRY_NAME"
echo "   Logs: docker logs $REGISTRY_NAME"
