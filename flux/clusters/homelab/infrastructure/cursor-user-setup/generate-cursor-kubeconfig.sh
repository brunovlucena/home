#!/bin/bash

# Script to generate kubeconfig for cursor user
# This script creates a kubeconfig file that Cursor can use with read-only permissions

set -e

NAMESPACE="default"
SERVICE_ACCOUNT="cursor"
SECRET_NAME="cursor-token"
KUBECONFIG_FILE="cursor-kubeconfig.yaml"

echo "🔧 Generating kubeconfig for cursor user..."

# Get the current cluster info
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

echo "📋 Current cluster: $CLUSTER_NAME"
echo "🌐 Server: $CLUSTER_SERVER"

# Wait for the secret to be created and get the token
echo "⏳ Waiting for service account token..."
for i in {1..30}; do
    if kubectl get secret $SECRET_NAME -n $NAMESPACE >/dev/null 2>&1; then
        break
    fi
    echo "   Waiting for secret $SECRET_NAME... (attempt $i/30)"
    sleep 2
done

# Get the token from the secret
TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 --decode)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get token from secret $SECRET_NAME"
    exit 1
fi

echo "✅ Token retrieved successfully"

# Create the kubeconfig file
cat > $KUBECONFIG_FILE << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CLUSTER_CA
    server: $CLUSTER_SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: cursor
  name: cursor-context
current-context: cursor-context
users:
- name: cursor
  user:
    token: $TOKEN
EOF

echo "✅ Kubeconfig file generated: $KUBECONFIG_FILE"
echo ""
echo "📝 To use this kubeconfig with Cursor:"
echo "   1. Copy the $KUBECONFIG_FILE to your desired location"
echo "   2. Set the KUBECONFIG environment variable or use --kubeconfig flag"
echo "   3. Test with: kubectl --kubeconfig=$KUBECONFIG_FILE get pods"
echo ""
echo "🔒 This user has read-only access and CANNOT delete resources"
echo ""
echo "🧪 Testing the kubeconfig..."
if kubectl --kubeconfig=$KUBECONFIG_FILE get namespaces >/dev/null 2>&1; then
    echo "✅ Kubeconfig test successful! cursor user can read resources"
else
    echo "❌ Kubeconfig test failed"
    exit 1
fi

echo ""
echo "🚫 Testing delete permissions (should fail)..."
if kubectl --kubeconfig=$KUBECONFIG_FILE delete pod --all --dry-run=client >/dev/null 2>&1; then
    echo "⚠️  WARNING: cursor user has delete permissions (this should not happen)"
else
    echo "✅ Confirmed: cursor user cannot delete resources"
fi

echo ""
echo "🎉 Setup complete! Your cursor kubeconfig is ready to use."
