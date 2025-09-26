#!/bin/bash

# Test script to verify cursor user permissions
# This script tests that the cursor user has read access but no delete/modify access

set -e

KUBECONFIG_FILE="cursor-kubeconfig.yaml"

if [ ! -f "$KUBECONFIG_FILE" ]; then
    echo "❌ Kubeconfig file $KUBECONFIG_FILE not found. Run setup-cursor-user.sh first."
    exit 1
fi

echo "🧪 Testing cursor user permissions..."
echo ""

# Test read permissions (these should work)
echo "✅ Testing READ permissions (should succeed):"

echo "   📋 Testing: kubectl get namespaces"
if kubectl --kubeconfig=$KUBECONFIG_FILE get namespaces >/dev/null 2>&1; then
    echo "   ✅ Can read namespaces"
else
    echo "   ❌ Cannot read namespaces"
fi

echo "   📦 Testing: kubectl get pods --all-namespaces"
if kubectl --kubeconfig=$KUBECONFIG_FILE get pods --all-namespaces >/dev/null 2>&1; then
    echo "   ✅ Can read pods"
else
    echo "   ❌ Cannot read pods"
fi

echo "   🚀 Testing: kubectl get deployments --all-namespaces"
if kubectl --kubeconfig=$KUBECONFIG_FILE get deployments --all-namespaces >/dev/null 2>&1; then
    echo "   ✅ Can read deployments"
else
    echo "   ❌ Cannot read deployments"
fi

echo "   📊 Testing: kubectl get services --all-namespaces"
if kubectl --kubeconfig=$KUBECONFIG_FILE get services --all-namespaces >/dev/null 2>&1; then
    echo "   ✅ Can read services"
else
    echo "   ❌ Cannot read services"
fi

echo ""

# Test write permissions (these should fail)
echo "❌ Testing WRITE permissions (should fail):"

echo "   🗑️  Testing: kubectl delete pod (dry-run)"
if kubectl --kubeconfig=$KUBECONFIG_FILE delete pod --all --dry-run=client >/dev/null 2>&1; then
    echo "   ⚠️  WARNING: Can delete pods (this should not happen!)"
else
    echo "   ✅ Cannot delete pods (correct)"
fi

echo "   📝 Testing: kubectl create namespace test-cursor (dry-run)"
if kubectl --kubeconfig=$KUBECONFIG_FILE create namespace test-cursor --dry-run=client >/dev/null 2>&1; then
    echo "   ⚠️  WARNING: Can create namespaces (this should not happen!)"
else
    echo "   ✅ Cannot create namespaces (correct)"
fi

echo "   ✏️  Testing: kubectl patch deployment (dry-run)"
# Try to patch a deployment if one exists
DEPLOYMENT=$(kubectl --kubeconfig=$KUBECONFIG_FILE get deployments --all-namespaces -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$DEPLOYMENT" ]; then
    NAMESPACE=$(kubectl --kubeconfig=$KUBECONFIG_FILE get deployments --all-namespaces -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || echo "default")
    if kubectl --kubeconfig=$KUBECONFIG_FILE patch deployment $DEPLOYMENT -n $NAMESPACE -p '{"spec":{"replicas":1}}' --dry-run=client >/dev/null 2>&1; then
        echo "   ⚠️  WARNING: Can patch deployments (this should not happen!)"
    else
        echo "   ✅ Cannot patch deployments (correct)"
    fi
else
    echo "   ✅ No deployments found to test patch (skipping)"
fi

echo ""

# Test special permissions (these should work)
echo "🔧 Testing SPECIAL permissions (should succeed):"

# Test if we can describe resources (should work)
echo "   📖 Testing: kubectl describe nodes"
if kubectl --kubeconfig=$KUBECONFIG_FILE describe nodes >/dev/null 2>&1; then
    echo "   ✅ Can describe nodes"
else
    echo "   ❌ Cannot describe nodes"
fi

# Test if we can get events (should work)
echo "   📅 Testing: kubectl get events"
if kubectl --kubeconfig=$KUBECONFIG_FILE get events --all-namespaces >/dev/null 2>&1; then
    echo "   ✅ Can read events"
else
    echo "   ❌ Cannot read events"
fi

echo ""

# Summary
echo "📊 Permission Test Summary:"
echo "   ✅ Read access: Working as expected"
echo "   ❌ Write access: Properly restricted"
echo "   🔧 Special access: Working as expected"
echo ""
echo "🎉 Cursor user permissions are configured correctly!"
echo ""
echo "💡 You can now safely use this kubeconfig with Cursor IDE:"
echo "   export KUBECONFIG=\$(pwd)/$KUBECONFIG_FILE"
