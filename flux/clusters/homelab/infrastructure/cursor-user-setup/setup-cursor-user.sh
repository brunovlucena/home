#!/bin/bash

# Complete setup script for cursor user with read-only permissions
# This script will create all necessary Kubernetes resources and generate a kubeconfig

set -e

echo "🚀 Setting up cursor user with read-only permissions..."
echo ""

# Apply the Kubernetes resources
echo "📋 Creating ServiceAccount..."
kubectl apply -f 01-serviceaccount.yaml

echo "🔐 Creating ClusterRole with read-only permissions..."
kubectl apply -f 02-clusterrole.yaml

echo "🔗 Creating ClusterRoleBinding..."
kubectl apply -f 03-clusterrolebinding.yaml

echo ""
echo "⏳ Waiting for resources to be ready..."
sleep 5

# Generate the kubeconfig
echo "🔧 Generating kubeconfig..."
chmod +x generate-cursor-kubeconfig.sh
./generate-cursor-kubeconfig.sh

echo ""
echo "✅ Setup complete!"
echo ""
echo "📁 Files created:"
echo "   - cursor-kubeconfig.yaml (use this with Cursor)"
echo ""
echo "🔒 Security features:"
echo "   ✅ Read-only access to all Kubernetes resources"
echo "   ✅ Can exec into pods for debugging"
echo "   ✅ Can view logs and metrics"
echo "   ❌ CANNOT delete, create, or modify resources"
echo ""
echo "💡 Usage with Cursor:"
echo "   export KUBECONFIG=\$(pwd)/cursor-kubeconfig.yaml"
echo "   kubectl get pods  # This will work"
echo "   kubectl delete pod <name>  # This will fail (as intended)"
