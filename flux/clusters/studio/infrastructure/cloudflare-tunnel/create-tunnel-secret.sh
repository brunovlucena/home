#!/bin/bash

# 🔐 Cloudflare Tunnel Secret Creation Script
# 
# This script helps create the tunnel token secret for Cloudflare tunnel deployment.
# 
# Usage:
#   ./create-tunnel-secret.sh <tunnel_token>
#
# Example:
#   ./create-tunnel-secret.sh "eyJhIjoiNWFiNGU5Z..."

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if tunnel token is provided
if [ $# -eq 0 ]; then
    print_error "Tunnel token is required!"
    echo ""
    echo "Usage: $0 <tunnel_token>"
    echo ""
    echo "Example:"
    echo "  $0 \"eyJhIjoiNWFiNGU5Z...\""
    echo ""
    echo "To get your tunnel token:"
    echo "  1. Go to Cloudflare Zero Trust dashboard"
    echo "  2. Navigate to Networks > Tunnels"
    echo "  3. Create a new tunnel or select existing one"
    echo "  4. Copy the token from the installation command"
    exit 1
fi

TUNNEL_TOKEN="$1"
NAMESPACE="cloudflare-tunnel"
SECRET_NAME="tunnel-token"

print_status "Creating Cloudflare tunnel secret..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if namespace exists, create if not
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_status "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE"
    print_success "Namespace created: $NAMESPACE"
else
    print_status "Namespace already exists: $NAMESPACE"
fi

# Check if secret already exists
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    print_warning "Secret '$SECRET_NAME' already exists in namespace '$NAMESPACE'"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Aborted. Secret not updated."
        exit 0
    fi
    
    # Delete existing secret
    print_status "Deleting existing secret..."
    kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
fi

# Create the secret
print_status "Creating secret with tunnel token..."
kubectl create secret generic "$SECRET_NAME" \
    --from-literal=token="$TUNNEL_TOKEN" \
    --namespace="$NAMESPACE"

print_success "Secret '$SECRET_NAME' created successfully in namespace '$NAMESPACE'"

# Verify the secret
print_status "Verifying secret creation..."
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    print_success "Secret verification successful!"
    echo ""
    print_status "You can now deploy the Cloudflare tunnel using:"
    echo "  kubectl apply -f deployment.yaml"
    echo ""
    print_status "Or if using Flux GitOps, the tunnel will be deployed automatically."
else
    print_error "Secret verification failed!"
    exit 1
fi
