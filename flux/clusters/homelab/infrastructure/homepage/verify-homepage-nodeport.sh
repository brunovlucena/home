#!/bin/bash

# Script to verify NodePort services for Bruno Homepage API and Frontend
# This script checks if the services are accessible on the configured ports

echo "🔍 Verifying NodePort services for Bruno Homepage..."
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if kind cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster is not accessible"
    echo "   Make sure your kind cluster is running: kind get clusters"
    exit 1
fi

echo "✅ Kubernetes cluster is accessible"
echo ""

# Check Homepage API NodePort service
echo "🔍 Checking Homepage API NodePort service..."
API_SERVICE=$(kubectl get service -l app.kubernetes.io/name=bruno-site-api-nodeport 2>/dev/null)
if [ $? -eq 0 ] && [ ! -z "$API_SERVICE" ]; then
    echo "✅ Homepage API NodePort service exists"
    echo "   Service details:"
    kubectl get service -l app.kubernetes.io/name=bruno-site-api-nodeport -o wide
    echo ""
    echo "🌐 Homepage API should be accessible at: http://localhost:31110"
    echo "   (Port 30110 in container maps to 31110 on host)"
    echo "   Metrics endpoint: http://localhost:31111/metrics"
else
    echo "❌ Homepage API NodePort service not found"
    echo "   Make sure the homepage is deployed with the updated Helm chart"
fi
echo ""

# Check Homepage Frontend NodePort service
echo "🔍 Checking Homepage Frontend NodePort service..."
FRONTEND_SERVICE=$(kubectl get service -l app.kubernetes.io/name=bruno-site-frontend-nodeport 2>/dev/null)
if [ $? -eq 0 ] && [ ! -z "$FRONTEND_SERVICE" ]; then
    echo "✅ Homepage Frontend NodePort service exists"
    echo "   Service details:"
    kubectl get service -l app.kubernetes.io/name=bruno-site-frontend-nodeport -o wide
    echo ""
    echo "🌐 Homepage Frontend should be accessible at: http://localhost:31120"
    echo "   (Port 30120 in container maps to 31120 on host)"
    echo "   Metrics endpoint: http://localhost:31121/metrics"
else
    echo "❌ Homepage Frontend NodePort service not found"
    echo "   Make sure the homepage is deployed with the updated Helm chart"
fi
echo ""

# Check if pods are running
echo "🔍 Checking if Homepage pods are running..."
API_PODS=$(kubectl get pods -l app.kubernetes.io/component=api --no-headers 2>/dev/null | wc -l)
FRONTEND_PODS=$(kubectl get pods -l app.kubernetes.io/component=frontend --no-headers 2>/dev/null | wc -l)

if [ "$API_PODS" -gt 0 ]; then
    echo "✅ Homepage API pods are running ($API_PODS pods)"
else
    echo "❌ No Homepage API pods found"
fi

if [ "$FRONTEND_PODS" -gt 0 ]; then
    echo "✅ Homepage Frontend pods are running ($FRONTEND_PODS pods)"
else
    echo "❌ No Homepage Frontend pods found"
fi

echo ""
echo "📋 Summary:"
echo "   - Homepage API: http://localhost:31110"
echo "   - Homepage Frontend: http://localhost:31120"
echo "   - API Metrics: http://localhost:31111/metrics"
echo "   - Frontend Metrics: http://localhost:31121/metrics"
echo ""
echo "💡 To apply the changes:"
echo "   1. Recreate the kind cluster with: kind delete cluster homelab && kind create cluster --config kind.yaml"
echo "   2. Redeploy the homepage with the updated Helm chart"
echo ""
echo "🌐 External access (from other machines on your network):"
echo "   - Homepage API: http://192.168.0.12:31110"
echo "   - Homepage Frontend: http://192.168.0.12:31120"
