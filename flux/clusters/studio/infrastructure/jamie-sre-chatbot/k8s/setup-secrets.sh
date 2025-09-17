#!/bin/bash
# Setup script for Jamie SRE Chatbot secrets
# This script helps you create the required secrets for the Slack bot

set -e

echo "🤖 Jamie SRE Chatbot - Secrets Setup"
echo "===================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace chatbots &> /dev/null; then
    echo "📦 Creating namespace..."
    kubectl apply -f namespace.yaml
fi

echo ""
echo "🔐 Setting up Slack secrets..."
echo "You'll need the following tokens from your Slack app:"
echo "1. Bot User OAuth Token (starts with xoxb-)"
echo "2. Signing Secret (starts with xoxs-)"
echo "3. App-Level Token (starts with xapp-)"
echo ""

# Get tokens from user
read -p "Enter your Slack Bot Token (xoxb-...): " SLACK_BOT_TOKEN
read -p "Enter your Slack Signing Secret (xoxs-...): " SLACK_SIGNING_SECRET
read -p "Enter your Slack App Token (xapp-...): " SLACK_APP_TOKEN

# Validate tokens
if [[ ! $SLACK_BOT_TOKEN =~ ^xoxb- ]]; then
    echo "❌ Invalid Bot Token format. Should start with 'xoxb-'"
    exit 1
fi

if [[ ! $SLACK_SIGNING_SECRET =~ ^xoxs- ]]; then
    echo "❌ Invalid Signing Secret format. Should start with 'xoxs-'"
    exit 1
fi

if [[ ! $SLACK_APP_TOKEN =~ ^xapp- ]]; then
    echo "❌ Invalid App Token format. Should start with 'xapp-'"
    exit 1
fi

# Encode tokens
BOT_TOKEN_B64=$(echo -n "$SLACK_BOT_TOKEN" | base64)
SIGNING_SECRET_B64=$(echo -n "$SLACK_SIGNING_SECRET" | base64)
APP_TOKEN_B64=$(echo -n "$SLACK_APP_TOKEN" | base64)

# Check if kubeseal is available
if ! command -v kubeseal &> /dev/null; then
    echo "❌ kubeseal is not installed. Please install it first."
    exit 1
fi

# Create sealed secret
echo "🔧 Creating sealed secret..."

# Create temporary secret file
cat <<EOF > /tmp/jamie-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: jamie-sre-chatbot-secrets
  namespace: chatbots
  labels:
    app: jamie-sre-chatbot
    app.kubernetes.io/name: jamie-sre-chatbot
    app.kubernetes.io/component: slack-bot
    app.kubernetes.io/part-of: bruno-infrastructure
type: Opaque
data:
  SLACK_BOT_TOKEN: $BOT_TOKEN_B64
  SLACK_SIGNING_SECRET: $SIGNING_SECRET_B64
  SLACK_APP_TOKEN: $APP_TOKEN_B64
  LOGFIRE_TOKEN: $(echo -n "" | base64)
EOF

# Create sealed secret using kubeseal
kubeseal --format=yaml < /tmp/jamie-secret.yaml > jamie-sre-chatbot-sealed-secret.yaml

# Apply the sealed secret
kubectl apply -f jamie-sre-chatbot-sealed-secret.yaml

# Clean up
rm -f /tmp/jamie-secret.yaml

echo ""
echo "✅ Secrets created successfully!"
echo ""
echo "🚀 Next steps:"
echo "1. Apply the remaining manifests: kubectl apply -k ."
echo "2. Check pod status: kubectl get pods -n chatbots"
echo "3. Check logs: kubectl logs -f deployment/jamie-sre-chatbot -n chatbots"
echo ""
echo "📚 For more information, see the README.md file"
