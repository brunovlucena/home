#!/bin/bash

# Create PagerDuty secrets for Alertmanager
# This script creates sealed secrets for PagerDuty integration

set -e

NAMESPACE="prometheus"
SECRET_NAME="pagerduty-secrets"

echo "🔐 Creating PagerDuty secrets for Alertmanager..."

# Check if kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
    echo "❌ kubeseal is not installed. Please install it first."
    echo "   On macOS: brew install kubeseal"
    echo "   On Linux: https://github.com/bitnami-labs/sealed-secrets#installation"
    exit 1
fi

# Check if we have the public key
if ! kubectl get secret -n flux-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active &> /dev/null; then
    echo "❌ Sealed secrets public key not found. Please ensure sealed-secrets is installed."
    exit 1
fi

# Get PagerDuty service key from environment variable
echo "📝 Using PagerDuty service key from environment variable..."
if [ -z "$PAGERDUTY_SERVICE_KEY" ]; then
    echo "❌ PAGERDUTY_SERVICE_KEY environment variable is not set"
    echo "   Please set it in your ~/.zshrc: export PAGERDUTY_SERVICE_KEY=your_key_here"
    exit 1
fi

echo "✅ Found PagerDuty service key in environment"

# Get Slack webhook URL from environment variable (optional)
echo "📝 Checking for Slack webhook URL in environment variable..."
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo "✅ Found Slack webhook URL in environment"
else
    echo "ℹ️  No SLACK_WEBHOOK_URL environment variable found (optional)"
fi

# Create the secret
echo "🔧 Creating sealed secret..."

# Download public key if not exists
if [ ! -f "public.pem" ]; then
    echo "📥 Downloading sealed secrets public key..."
    kubeseal --fetch-cert --controller-name=sealed-secrets --controller-namespace=flux-system > public.pem
    if [ $? -ne 0 ]; then
        echo "❌ Failed to download public key"
        exit 1
    fi
fi

# Create temporary secret file
cat > /tmp/pagerduty-secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
type: Opaque
data:
  pagerduty-service-key: $(echo -n "${PAGERDUTY_SERVICE_KEY}" | base64)
EOF

# Add Slack webhook if provided
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    cat >> /tmp/pagerduty-secret.yaml << EOF
  slack-webhook-url: $(echo -n "${SLACK_WEBHOOK_URL}" | base64)
EOF
fi

# Seal the secret
echo "🔐 Sealing the secret..."
kubeseal --format=yaml --cert=public.pem < /tmp/pagerduty-secret.yaml > pagerduty-sealed-secret.yaml

if [ $? -ne 0 ]; then
    echo "❌ Failed to seal the secret"
    rm -f /tmp/pagerduty-secret.yaml
    exit 1
fi

# Clean up
rm -f /tmp/pagerduty-secret.yaml

echo "✅ PagerDuty sealed secret created: pagerduty-sealed-secret.yaml"
echo ""
echo "📋 Next steps:"
echo "1. Apply the sealed secret: kubectl apply -f pagerduty-sealed-secret.yaml"
echo "2. The Helm release will automatically pick up the secret and inject it as environment variables"
echo "3. Alertmanager will use the environment variables in the configuration"
echo ""
echo "🔍 To verify the secret was created:"
echo "   kubectl get secret ${SECRET_NAME} -n ${NAMESPACE}"
echo ""
echo "📖 To view the secret (base64 encoded):"
echo "   kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o yaml"
echo ""
echo "🚀 To apply the changes:"
echo "   kubectl apply -k ."
echo ""
echo "🔍 To verify the secret was created:"
echo "   kubectl get secret ${SECRET_NAME} -n ${NAMESPACE}"
echo ""
echo "🔧 To check Alertmanager logs:"
echo "   kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=alertmanager"
echo ""
echo "🧪 To test the integration:"
echo "   1. Check Alertmanager UI: kubectl port-forward -n ${NAMESPACE} svc/alertmanager-prometheus-operator-kube-p-alertmanager 9093:9093"
echo "   2. Visit: http://localhost:9093"
echo "   3. Trigger a test alert by deleting a kube-proxy pod"
echo ""