#!/bin/bash

# =============================================================================
# 🔄 RESTORE SEALED SECRETS KEYS
# =============================================================================
# This script restores sealed secrets keys from backup to recover from
# accidental deletion or disaster recovery scenarios
#
# Usage: ./restore-sealed-secrets-keys.sh <backup-directory>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Show usage information
show_usage() {
    echo "Usage: $0 <backup-directory> [--force]"
    echo
    echo "Arguments:"
    echo "  backup-directory    Path to the backup directory containing sealed secrets keys"
    echo "  --force            Skip confirmation prompts (use with caution)"
    echo
    echo "Example:"
    echo "  $0 ./backups/studio_20241215_143022"
    echo
    echo "Required files in backup directory:"
    echo "  - sealed-secrets-private-key.yaml"
    echo "  - sealed-secrets-public-cert.pem"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if kubeseal is available
    if ! command -v kubeseal &> /dev/null; then
        print_error "kubeseal is not installed. Please install it first:"
        echo "  macOS: brew install kubeseal"
        echo "  Linux: Download from https://github.com/bitnami-labs/sealed-secrets/releases"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Validate backup directory
validate_backup_directory() {
    local backup_dir="$1"
    
    print_status "Validating backup directory..."
    
    # Check if directory exists
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory does not exist: $backup_dir"
        exit 1
    fi
    
    # Check for required files
    local required_files=(
        "sealed-secrets-private-key.yaml"
        "sealed-secrets-public-cert.pem"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$backup_dir/$file" ]; then
            print_error "Required file missing: $backup_dir/$file"
            exit 1
        fi
    done
    
    # Check for checksums if available
    if [ -f "$backup_dir/checksums.sha256" ]; then
        print_status "Verifying backup integrity..."
        cd "$backup_dir"
        if sha256sum -c checksums.sha256 > /dev/null 2>&1; then
            print_success "Backup integrity verified"
        else
            print_warning "Backup integrity check failed - proceeding with caution"
        fi
    else
        print_warning "No checksums found - cannot verify backup integrity"
    fi
    
    print_success "Backup directory validated"
}

# Check current sealed secrets status
check_current_status() {
    print_status "Checking current sealed secrets status..."
    
    # Check if sealed secrets controller is running
    if kubectl get pods -n kube-system -l name=sealed-secrets-controller &> /dev/null; then
        print_info "Sealed Secrets controller is currently running"
        
        # Check if keys exist
        if kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key &> /dev/null; then
            print_warning "⚠️  Sealed secrets keys already exist in the cluster!"
            print_warning "This will overwrite the existing keys."
            return 1
        fi
    else
        print_warning "Sealed Secrets controller is not running"
    fi
    
    return 0
}

# Restore private key
restore_private_key() {
    local backup_dir="$1"
    
    print_status "Restoring private key..."
    
    # Apply the private key secret
    if kubectl apply -f "$backup_dir/sealed-secrets-private-key.yaml"; then
        print_success "Private key restored successfully"
    else
        print_error "Failed to restore private key"
        return 1
    fi
}

# Restart sealed secrets controller
restart_controller() {
    print_status "Restarting Sealed Secrets controller..."
    
    # Delete controller pod to force restart
    if kubectl delete pod -n kube-system -l name=sealed-secrets-controller; then
        print_success "Controller pod deleted"
    else
        print_warning "Failed to delete controller pod - may not exist"
    fi
    
    # Wait for controller to be ready
    print_status "Waiting for controller to be ready..."
    local timeout=60
    local count=0
    
    while [ $count -lt $timeout ]; do
        if kubectl get pods -n kube-system -l name=sealed-secrets-controller --field-selector=status.phase=Running &> /dev/null; then
            print_success "Controller is ready"
            return 0
        fi
        
        sleep 2
        count=$((count + 2))
        echo -n "."
    done
    
    echo
    print_error "Controller failed to start within ${timeout} seconds"
    return 1
}

# Verify restoration
verify_restoration() {
    print_status "Verifying restoration..."
    
    # Check if controller is running
    if ! kubectl get pods -n kube-system -l name=sealed-secrets-controller --field-selector=status.phase=Running &> /dev/null; then
        print_error "Controller is not running"
        return 1
    fi
    
    # Check if keys exist
    if ! kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key &> /dev/null; then
        print_error "Private key not found in cluster"
        return 1
    fi
    
    # Test public key retrieval
    if kubeseal --fetch-cert > /dev/null 2>&1; then
        print_success "Public key is accessible"
    else
        print_error "Failed to retrieve public key"
        return 1
    fi
    
    print_success "Restoration verified successfully"
}

# Test with a sample secret
test_restoration() {
    print_status "Testing restoration with sample secret..."
    
    # Create a test secret
    cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: v1
kind: Secret
metadata:
  name: test-restoration-secret
  namespace: default
type: Opaque
data:
  test: $(echo -n "test-value" | base64)
EOF
    
    # Seal the secret
    if kubectl get secret test-restoration-secret -n default -o yaml | kubeseal --format=yaml > /tmp/test-sealed-secret.yaml 2>/dev/null; then
        print_success "Sample secret sealing test passed"
        
        # Clean up test secret
        kubectl delete secret test-restoration-secret -n default > /dev/null 2>&1 || true
        rm -f /tmp/test-sealed-secret.yaml
        
        return 0
    else
        print_error "Sample secret sealing test failed"
        return 1
    fi
}

# Confirmation prompt
confirm_restoration() {
    local backup_dir="$1"
    local force="$2"
    
    if [ "$force" = "--force" ]; then
        return 0
    fi
    
    echo
    print_warning "⚠️  WARNING: This will restore sealed secrets keys to your cluster"
    print_info "Backup directory: $backup_dir"
    echo
    
    # Check if keys already exist
    if kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key &> /dev/null; then
        print_error "⚠️  CRITICAL: Sealed secrets keys already exist!"
        print_error "This operation will OVERWRITE existing keys."
        print_error "All existing sealed secrets may become inaccessible if this is the wrong backup!"
        echo
    fi
    
    read -p "Are you sure you want to proceed? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Restoration cancelled"
        exit 0
    fi
}

# Main restoration function
main() {
    local backup_dir="$1"
    local force="$2"
    
    # Validate arguments
    if [ -z "$backup_dir" ]; then
        show_usage
        exit 1
    fi
    
    print_status "Starting Sealed Secrets restoration process..."
    print_info "Backup directory: $backup_dir"
    
    # Check prerequisites
    check_prerequisites
    
    # Validate backup directory
    validate_backup_directory "$backup_dir"
    
    # Check current status
    check_current_status
    local keys_exist=$?
    
    # Confirmation
    confirm_restoration "$backup_dir" "$force"
    
    # Restore private key
    restore_private_key "$backup_dir" || exit 1
    
    # Restart controller
    restart_controller || exit 1
    
    # Verify restoration
    verify_restoration || exit 1
    
    # Test restoration
    test_restoration || exit 1
    
    # Final summary
    echo
    print_success "🎉 Restoration completed successfully!"
    print_info "Sealed secrets keys have been restored and verified"
    
    if [ $keys_exist -eq 1 ]; then
        print_warning "⚠️  Note: Previous keys were overwritten"
    fi
    
    echo
    print_info "Next steps:"
    echo "  1. Test that your existing sealed secrets are still accessible"
    echo "  2. Verify that new secrets can be sealed properly"
    echo "  3. Update your backup strategy if needed"
}

# Run main function
main "$@"
