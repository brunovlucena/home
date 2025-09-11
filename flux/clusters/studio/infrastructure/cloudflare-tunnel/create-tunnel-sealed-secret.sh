#!/bin/bash

# =============================================================================
# 🔐 CREATE CLOUDFLARE TUNNEL SEALED SECRET
# =============================================================================
# This script creates a sealed secret for the Cloudflare tunnel token
# Run this script after Sealed Secrets controller is installed

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

# Check if kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
    print_error "kubeseal is not installed. Please install it first:"
    echo "  macOS: brew install kubeseal"
    echo "  Linux: Download from https://github.com/bitnami-labs/sealed-secrets/releases"
    exit 1
fi

# Check if tunnel token is provided via environment variable
if [ -z "$CLOUDFLARE_TOKEN" ]; then
    print_error "CLOUDFLARE_TOKEN environment variable is required!"
    echo ""
    echo "Usage: export CLOUDFLARE_TOKEN=\"your_tunnel_token\" && $0"
    echo ""
    echo "Example:"
    echo "  export CLOUDFLARE_TOKEN=\"eyJhIjoiNWFiNGU5Z...\""
    echo "  $0"
    echo ""
    echo "To get your tunnel token:"
    echo "  1. Go to Cloudflare Zero Trust dashboard"
    echo "  2. Navigate to Networks > Tunnels"
    echo "  3. Create a new tunnel or select existing one"
    echo "  4. Copy the token from the installation command"
    exit 1
fi

TUNNEL_TOKEN="$CLOUDFLARE_TOKEN"
NAMESPACE="cloudflare-tunnel"
SECRET_NAME="tunnel-token"

print_status "Creating Cloudflare tunnel sealed secret for namespace: $NAMESPACE"

# Create the sealed secret
cat <<EOF | kubeseal --format=yaml > tunnel-token-sealed-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: cloudflare-tunnel
    app.kubernetes.io/component: secret
    app.kubernetes.io/part-of: home-infrastructure
type: Opaque
data:
  token: $(echo -n "$TUNNEL_TOKEN" | base64)
EOF

# Verify the generated file
print_status "Verifying generated file..."

if [ -f "tunnel-token-sealed-secret.yaml" ]; then
    print_success "Sealed secret created successfully!"
    print_status "File created:"
    echo "  - tunnel-token-sealed-secret.yaml"
    
    print_status "Apply the sealed secret to your cluster:"
    echo "  kubectl apply -f tunnel-token-sealed-secret.yaml"
    
    print_status "Or apply all cloudflare-tunnel resources:"
    echo "  kubectl apply -k ."
    
    print_warning "IMPORTANT: The tunnel token is now encrypted and safe to commit to Git"
    print_status "The Sealed Secrets controller will automatically decrypt it in the cluster"
else
    print_error "Failed to create sealed secret file!"
    exit 1
fi
