#!/bin/bash

# =============================================================================
# 🔐 CREATE STRAVA SEALED SECRETS
# =============================================================================
# This script creates sealed secrets for the Strava datasource in Grafana
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

# Strava credentials from environment variables
STRAVA_CLIENT_ID="${STRAVA_CLIENT_ID}"
STRAVA_CLIENT_SECRET="${STRAVA_CLIENT_SECRET}"
STRAVA_ACCESS_TOKEN="${STRAVA_ACCESS_TOKEN}"
STRAVA_REFRESH_TOKEN="${STRAVA_REFRESH_TOKEN}"
STRAVA_EXPIRES_AT="${STRAVA_EXPIRES_AT:-}"

# Validate environment variables
if [ -z "$STRAVA_CLIENT_ID" ]; then
    print_error "STRAVA_CLIENT_ID environment variable is not set"
    exit 1
fi

if [ -z "$STRAVA_CLIENT_SECRET" ]; then
    print_error "STRAVA_CLIENT_SECRET environment variable is not set"
    exit 1
fi

if [ -z "$STRAVA_ACCESS_TOKEN" ]; then
    print_error "STRAVA_ACCESS_TOKEN environment variable is not set"
    exit 1
fi

if [ -z "$STRAVA_REFRESH_TOKEN" ]; then
    print_error "STRAVA_REFRESH_TOKEN environment variable is not set"
    exit 1
fi

print_status "Extracting Sealed Secrets public key"
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath='{.items[0].data.tls\.crt}' | base64 -d > sealed-secrets-public-key.pem

print_status "Creating sealed secrets for prometheus namespace"

# Create Strava credentials secret
cat <<EOF | kubeseal --cert=sealed-secrets-public-key.pem --format=yaml > strava-sealed-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: strava-secrets
  namespace: prometheus
type: Opaque
data:
  client-id: $(echo -n "$STRAVA_CLIENT_ID" | base64)
  client-secret: $(echo -n "$STRAVA_CLIENT_SECRET" | base64)
  access-token: $(echo -n "$STRAVA_ACCESS_TOKEN" | base64)
  refresh-token: $(echo -n "$STRAVA_REFRESH_TOKEN" | base64)
  expires-at: $(echo -n "$STRAVA_EXPIRES_AT" | base64)
EOF

print_success "Sealed secrets created successfully!"
print_status "Files created:"
echo "  - strava-sealed-secret.yaml"

print_status "Cleaning up temporary files"
rm -f sealed-secrets-public-key.pem

print_status "Apply the sealed secrets to your cluster:"
echo "  kubectl apply -f strava-sealed-secret.yaml"
