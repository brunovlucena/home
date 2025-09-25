#!/bin/bash

# Linkerd Installation Script for Homelab
# This script automates the Linkerd installation process

set -euo pipefail

CLUSTER_NAME="${1:-homelab}"
CONTEXT="kind-${CLUSTER_NAME}"
CLEANUP_EXISTING="${2:-false}"

echo "🚀 Installing Linkerd on cluster: ${CLUSTER_NAME}"

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

# Function to check if Linkerd is already installed and working
# This function gracefully handles the case where Linkerd is already installed
# and working properly, providing useful status information instead of failing
check_existing_installation() {
    if kubectl --context "${CONTEXT}" get namespace linkerd &> /dev/null; then
        echo "⚠️  Linkerd namespace already exists"
        
        # Check if Linkerd is actually working
        echo "🔍 Checking if Linkerd is already working..."
        # Use a more lenient check - just verify pods are running
        RUNNING_PODS=$(kubectl --context "${CONTEXT}" get pods -n linkerd --field-selector=status.phase=Running --no-headers | wc -l)
        echo "Found $RUNNING_PODS running pods in linkerd namespace"
        if [ "$RUNNING_PODS" -gt 0 ]; then
            echo "✅ Linkerd is already installed and working properly"
            echo ""
            echo "📊 Current Linkerd Status:"
            echo "========================="
            linkerd version --context "${CONTEXT}"
            echo ""
            echo "🔍 Health Check Summary:"
            timeout 30s linkerd check --context "${CONTEXT}" --output short || echo "⚠️  Some checks have warnings but Linkerd is functional"
            echo ""
            echo "ℹ️  Skipping installation. Use 'CLEANUP_EXISTING=true' to reinstall"
            echo "ℹ️  Or run: make linkerd-install-clean"
            echo ""
            echo "📖 Available commands:"
            echo "  - Check status: make linkerd-status"
            echo "  - Open dashboard: make linkerd-dashboard"
            echo "  - Run health checks: make linkerd-check"
            exit 0
        else
            echo "⚠️  Linkerd namespace exists but installation appears incomplete or broken"
            if [ "${CLEANUP_EXISTING}" = "true" ]; then
                echo "🧹 Cleaning up existing Linkerd installation..."
                linkerd uninstall --context "${CONTEXT}" || true
                kubectl --context "${CONTEXT}" delete namespace linkerd --ignore-not-found=true || true
                kubectl --context "${CONTEXT}" delete namespace linkerd-viz --ignore-not-found=true || true
                echo "✅ Existing installation cleaned up"
            else
                echo "ℹ️  Use 'CLEANUP_EXISTING=true' to clean up existing installation"
                echo "ℹ️  Or run: linkerd uninstall --context ${CONTEXT}"
                exit 1
            fi
        fi
    fi
}

# Function to run pre-install checks
run_pre_checks() {
    echo "🔍 Running Linkerd pre-install checks..."
    if ! timeout 60s linkerd check --pre --context "${CONTEXT}"; then
        echo "❌ Pre-install checks failed"
        echo "💡 Try running with cleanup: scripts/install-linkerd.sh ${CLUSTER_NAME} true"
        exit 1
    fi
    echo "✅ Pre-install checks passed"
}

# Function to install Gateway API CRDs (required for Linkerd)
install_gateway_api_crds() {
    echo "🌐 Installing Gateway API CRDs..."
    if ! kubectl --context "${CONTEXT}" apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml; then
        echo "❌ Failed to install Gateway API CRDs"
        exit 1
    fi
    echo "✅ Gateway API CRDs installed"
}

# Function to install Linkerd CRDs
install_crds() {
    echo "📦 Installing Linkerd CRDs..."
    if ! linkerd install --crds --context "${CONTEXT}" | kubectl --context "${CONTEXT}" apply -f -; then
        echo "❌ Failed to install Linkerd CRDs"
        exit 1
    fi
    echo "✅ Linkerd CRDs installed"
}

# Function to install Linkerd control plane
install_control_plane() {
    echo "🎛️ Installing Linkerd control plane..."
    if ! linkerd install --context "${CONTEXT}" | kubectl --context "${CONTEXT}" apply -f -; then
        echo "❌ Failed to install Linkerd control plane"
        exit 1
    fi
    echo "✅ Linkerd control plane installed"
}

# Function to wait for Linkerd to be ready
wait_for_ready() {
    echo "⏳ Waiting for Linkerd to be ready..."
    if ! timeout 300s linkerd check --context "${CONTEXT}" --wait=300s; then
        echo "❌ Linkerd failed to become ready"
        exit 1
    fi
    echo "✅ Linkerd is ready"
}

# Function to install Linkerd Viz (observability)
install_viz() {
    echo "📊 Installing Linkerd Viz..."
    if ! linkerd viz install --context "${CONTEXT}" | kubectl --context "${CONTEXT}" apply -f -; then
        echo "❌ Failed to install Linkerd Viz"
        exit 1
    fi
    
    # Wait for Viz to be ready
    echo "⏳ Waiting for Linkerd Viz to be ready..."
    if ! timeout 300s linkerd viz check --context "${CONTEXT}" --wait=300s; then
        echo "❌ Linkerd Viz failed to become ready"
        exit 1
    fi
    echo "✅ Linkerd Viz is ready"
}

# Function to show installation status
show_status() {
    echo "📋 Linkerd Installation Status:"
    echo "================================"
    linkerd version --context "${CONTEXT}"
    echo ""
    echo "🔍 Linkerd Health Check:"
    linkerd check --context "${CONTEXT}"
    echo ""
    echo "📊 Available Services:"
    kubectl --context "${CONTEXT}" get pods -n linkerd
    kubectl --context "${CONTEXT}" get pods -n linkerd-viz
}

# Main installation flow
main() {
    echo "🏠 Homelab Linkerd Installation"
    echo "==============================="
    
    check_linkerd_cli
    check_existing_installation
    install_gateway_api_crds
    run_pre_checks
    install_crds
    install_control_plane
    wait_for_ready
    install_viz
    show_status
    
    echo ""
    echo "🎉 Linkerd installation completed successfully!"
    echo ""
    echo "📖 Next steps:"
    echo "  - Access dashboard: linkerd viz dashboard --context ${CONTEXT}"
    echo "  - Check status: linkerd check --context ${CONTEXT}"
    echo "  - Inject services: kubectl --context ${CONTEXT} label namespace <namespace> linkerd.io/inject=enabled"
}

# Run main function
main "$@"
