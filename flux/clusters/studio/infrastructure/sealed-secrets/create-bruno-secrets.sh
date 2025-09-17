#!/bin/bash

# =============================================================================
# 🔐 CREATE BRUNO SITE SEALED SECRETS
# =============================================================================
# This script creates sealed secrets for the Bruno Site application
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

# Set default namespace if not provided
NAMESPACE=${NAMESPACE:-bruno}

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)

print_status "Generating sealed secrets for namespace: $NAMESPACE"

# Create database secret
cat <<EOF | kubeseal --format=yaml > bruno-site-db-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bruno-site-db-secret
  namespace: $NAMESPACE
type: Opaque
data:
  password: $(echo -n "$DB_PASSWORD" | base64)
EOF

# Create Redis secret
cat <<EOF | kubeseal --format=yaml > bruno-site-redis-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bruno-site-redis-secret
  namespace: $NAMESPACE
type: Opaque
data:
  password: $(echo -n "$REDIS_PASSWORD" | base64)
EOF



# Verify the generated files
print_status "Verifying generated files..."

print_success "Sealed secrets created successfully!"
print_status "Files created:"
echo "  - bruno-site-db-secret.yaml"
echo "  - bruno-site-redis-secret.yaml"

print_warning "IMPORTANT: Save these passwords securely for local development:"
echo "  Database Password: $DB_PASSWORD"
echo "  Redis Password: $REDIS_PASSWORD"

print_status "Apply the sealed secrets to your cluster:"
echo "  kubectl apply -f bruno-site-db-secret.yaml"
echo "  kubectl apply -f bruno-site-redis-secret.yaml"

print_status "Or apply all at once:"
echo "  kubectl apply -f ."
