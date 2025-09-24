#!/bin/bash

# =============================================================================
# 🔐 CREATE NGROK SEALED SECRETS
# =============================================================================
# This script creates sealed secrets for the Ngrok operator
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

# Ngrok credentials from environment variables
NGROK_AUTHTOKEN="${NGROK_AUTHTOKEN}"
NGROK_API_KEY="${NGROK_API_KEY}"

# Validate environment variables
if [ -z "$NGROK_AUTHTOKEN" ]; then
    print_error "NGROK_AUTHTOKEN environment variable is not set"
    exit 1
fi

if [ -z "$NGROK_API_KEY" ]; then
    print_error "NGROK_API_KEY environment variable is not set"
    exit 1
fi

print_status "Creating sealed secrets for ngrok-operator namespace"

# Create ngrok credentials secret
cat <<EOF | kubeseal --format=yaml > sealed-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ngrok-credentials
  namespace: ngrok-operator
type: Opaque
data:
  apiKey: $(echo -n "$NGROK_API_KEY" | base64)
  authtoken: $(echo -n "$NGROK_AUTHTOKEN" | base64)
EOF

print_success "Sealed secrets created successfully!"
print_status "Files created:"
echo "  - sealed-secrets.yaml"

print_status "Apply the sealed secrets to your cluster:"
echo "  kubectl apply -f sealed-secrets.yaml"
