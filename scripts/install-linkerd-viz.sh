#!/bin/bash

# Linkerd Viz Installation Script for Homelab
# This script installs Linkerd Viz programmatically

set -euo pipefail

CLUSTER_NAME="${1:-homelab}"
CONTEXT="kind-${CLUSTER_NAME}"

echo "📊 Installing Linkerd Viz on cluster: ${CLUSTER_NAME}"

# Function to check if linkerd CLI is installed
check_linkerd_cli() {
    if ! command -v linkerd &> /dev/null; then
        echo "❌ Linkerd CLI not found. Installing..."
        curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
        export PATH=$PATH:$HOME/.linkerd2/bin
    else
        echo "✅ Linkerd CLI found"
    fi
}

# Function to check if Linkerd is installed
check_linkerd_installed() {
    echo "🔍 Checking if Linkerd is installed..."
    RUNNING_PODS=$(kubectl --context "${CONTEXT}" get pods -n linkerd --field-selector=status.phase=Running --no-headers | wc -l)
    echo "Found $RUNNING_PODS running pods in linkerd namespace"
    if [ "$RUNNING_PODS" -eq 0 ]; then
        echo "❌ Linkerd is not installed or not working"
        echo "💡 Please install Linkerd first: make linkerd-install"
        exit 1
    fi
    echo "✅ Linkerd is installed and working"
}

# Function to check if Viz is already installed
check_viz_installed() {
    if kubectl --context "${CONTEXT}" get namespace linkerd-viz &> /dev/null; then
        echo "⚠️  Linkerd Viz namespace already exists"
        
        # Check if Viz is working
        VIZ_RUNNING_PODS=$(kubectl --context "${CONTEXT}" get pods -n linkerd-viz --field-selector=status.phase=Running --no-headers | wc -l)
        echo "Found $VIZ_RUNNING_PODS running pods in linkerd-viz namespace"
        if [ "$VIZ_RUNNING_PODS" -gt 0 ]; then
            echo "✅ Linkerd Viz is already installed and working"
            echo ""
            echo "📊 Current Viz Status:"
            timeout 30s linkerd viz check --context "${CONTEXT}" --output short || echo "⚠️  Some checks have warnings but Viz is functional"
            echo ""
            echo "ℹ️  Use 'make linkerd-dashboard' to access the dashboard"
            exit 0
        else
            echo "⚠️  Viz namespace exists but installation appears incomplete"
            echo "🧹 Cleaning up existing Viz installation..."
            kubectl --context "${CONTEXT}" delete namespace linkerd-viz --ignore-not-found=true || true
        fi
    fi
}

# Function to install Linkerd Viz
install_viz() {
    echo "📊 Installing Linkerd Viz..."
    if ! linkerd viz install --context "${CONTEXT}" | kubectl --context "${CONTEXT}" apply -f -; then
        echo "❌ Failed to install Linkerd Viz"
        exit 1
    fi
    echo "✅ Linkerd Viz installed"
}

# Function to wait for Viz to be ready
wait_for_viz() {
    echo "⏳ Waiting for Linkerd Viz to be ready..."
    if ! timeout 300s linkerd viz check --context "${CONTEXT}" --wait=300s; then
        echo "❌ Linkerd Viz failed to become ready"
        exit 1
    fi
    echo "✅ Linkerd Viz is ready"
}

# Function to show Viz status
show_viz_status() {
    echo "📋 Linkerd Viz Status:"
    echo "======================"
    timeout 60s linkerd viz check --context "${CONTEXT}" || echo "⚠️  Some checks have warnings but Viz is functional"
    echo ""
    echo "📊 Viz Pods:"
    kubectl --context "${CONTEXT}" get pods -n linkerd-viz
}

# Main installation flow
main() {
    echo "🏠 Homelab Linkerd Viz Installation"
    echo "==================================="
    
    check_linkerd_cli
    check_linkerd_installed
    check_viz_installed
    install_viz
    wait_for_viz
    show_viz_status
    
    echo ""
    echo "🎉 Linkerd Viz installation completed successfully!"
    echo ""
    echo "📖 Next steps:"
    echo "  - Access dashboard: make linkerd-dashboard"
    echo "  - Check Viz status: make linkerd-viz-status"
    echo "  - Or run: linkerd viz dashboard --context ${CONTEXT}"
}

# Run main function
main "$@"
