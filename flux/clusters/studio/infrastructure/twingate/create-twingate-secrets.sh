#!/bin/bash

# =============================================================================
# 🔐 CREATE TWINGATE SEALED SECRETS
# =============================================================================
# This script creates sealed secrets for the Twingate connector
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

# Twingate credentials from environment variables
TWINGATE_ACCESS_TOKEN="${TWINGATE_ACCESS_TOKEN}"
TWINGATE_REFRESH_TOKEN="${TWINGATE_REFRESH_TOKEN}"
TWINGATE_NETWORK="${TWINGATE_NETWORK:-bvlucena}"

# Validate environment variables
if [ -z "$TWINGATE_ACCESS_TOKEN" ]; then
    print_error "TWINGATE_ACCESS_TOKEN environment variable is not set"
    echo "Please set your Twingate access token:"
    echo "  export TWINGATE_ACCESS_TOKEN='your_access_token_here'"
    exit 1
fi

if [ -z "$TWINGATE_REFRESH_TOKEN" ]; then
    print_error "TWINGATE_REFRESH_TOKEN environment variable is not set"
    echo "Please set your Twingate refresh token:"
    echo "  export TWINGATE_REFRESH_TOKEN='your_refresh_token_here'"
    exit 1
fi

print_status "Creating sealed secrets for twingate namespace"
print_status "Network: $TWINGATE_NETWORK"

# Create Twingate credentials secret
cat <<EOF | kubeseal --format=yaml > twingate-credentials-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: twingate-credentials
  namespace: twingate
type: Opaque
data:
  TWINGATE_ACCESS_TOKEN: $(echo -n "$TWINGATE_ACCESS_TOKEN" | base64)
  TWINGATE_REFRESH_TOKEN: $(echo -n "$TWINGATE_REFRESH_TOKEN" | base64)
EOF

print_success "Sealed secrets created successfully!"
print_status "Files created:"
echo "  - twingate-credentials-secret.yaml"

print_warning "IMPORTANT: Keep your tokens secure and never commit them to Git!"

print_status "Apply the sealed secrets to your cluster:"
echo "  kubectl apply -f twingate-credentials-secret.yaml"

print_status "Verify the secret was created:"
echo "  kubectl get secrets -n twingate"
echo "  kubectl get sealedsecrets -n twingate"
