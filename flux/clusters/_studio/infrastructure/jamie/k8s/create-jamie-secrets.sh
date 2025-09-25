#!/bin/bash

# =============================================================================
# 🔐 CREATE JAMIE SRE CHATBOT SEALED SECRETS
# =============================================================================
# This script creates sealed secrets for the Jamie SRE Chatbot application
# Run this script after Sealed Secrets controller is installed
# 
# Prerequisites:
# - Environment variables must be set in current shell:
#   - SLACK_BOT_TOKEN
#   - SLACK_SIGNING_SECRET  
#   - SLACK_APP_TOKEN

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
NAMESPACE=${NAMESPACE:-chatbots}

# Check if required environment variables are set
print_status "Checking required environment variables..."

required_vars=("SLACK_BOT_TOKEN" "SLACK_SIGNING_SECRET" "SLACK_APP_TOKEN")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    print_error "Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    
    print_warning "Please export these variables in your current shell:"
    echo "  export SLACK_BOT_TOKEN='your-bot-token'"
    echo "  export SLACK_SIGNING_SECRET='your-signing-secret'"
    echo "  export SLACK_APP_TOKEN='your-app-token'"
    
    exit 1
fi

print_success "All required environment variables found!"

# Create the sealed secret
print_status "Creating sealed secret for namespace: $NAMESPACE"

cat <<EOF | kubeseal --format=yaml > jamie-sre-chatbot-sealed-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: jamie-sre-chatbot-secrets
  namespace: $NAMESPACE
  labels:
    app: jamie-sre-chatbot
    app.kubernetes.io/name: jamie-sre-chatbot
    app.kubernetes.io/component: slack-bot
    app.kubernetes.io/part-of: bruno-infrastructure
type: Opaque
data:
  SLACK_BOT_TOKEN: $(echo -n "$SLACK_BOT_TOKEN" | base64)
  SLACK_SIGNING_SECRET: $(echo -n "$SLACK_SIGNING_SECRET" | base64)
  SLACK_APP_TOKEN: $(echo -n "$SLACK_APP_TOKEN" | base64)
EOF

# Verify the generated file
print_status "Verifying generated file..."

if [ -f "jamie-sre-chatbot-sealed-secret.yaml" ]; then
    print_success "Sealed secret created successfully!"
    print_status "File created:"
    echo "  - jamie-sre-chatbot-sealed-secret.yaml"
    
    print_status "Apply the sealed secret to your cluster:"
    echo "  kubectl apply -f jamie-sre-chatbot-sealed-secret.yaml"
    
    print_status "Or apply with the kustomization:"
    echo "  kubectl apply -k ."
    
    print_warning "IMPORTANT: The sealed secret is now encrypted and safe to commit to git!"
else
    print_error "Failed to create sealed secret file!"
    exit 1
fi