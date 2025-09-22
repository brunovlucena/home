#!/bin/bash

# =============================================================================
# 🔐 BACKUP SEALED SECRETS KEYS
# =============================================================================
# This script creates secure backups of sealed secrets public and private keys
# to prevent accidental deletion and ensure disaster recovery capability
#
# Based on best practices from:
# - https://foxutech.com/bitnami-sealed-secrets-kubernetes-secret-management/
# - https://best-of-web.builder.io/library/bitnami-labs/sealed-secrets/
# - https://blog.andi95.de/en/2025/03/kubernetes-secrets-with-sealed-secrets/

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CLUSTER_NAME="${CLUSTER_NAME:-studio}"

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
    
    # Check if sealed secrets controller is running
    if ! kubectl get pods -n kube-system -l name=sealed-secrets-controller &> /dev/null; then
        print_error "Sealed Secrets controller is not running in kube-system namespace"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Create backup directory
create_backup_directory() {
    print_status "Creating backup directory..."
    
    # Create timestamped backup directory
    BACKUP_PATH="${BACKUP_DIR}/${CLUSTER_NAME}_${TIMESTAMP}"
    mkdir -p "${BACKUP_PATH}"
    
    # Set restrictive permissions (owner read/write only)
    chmod 700 "${BACKUP_PATH}"
    
    print_success "Backup directory created: ${BACKUP_PATH}"
    echo "${BACKUP_PATH}"
}

# Backup private key (CRITICAL - contains decryption capability)
backup_private_key() {
    local backup_path="$1"
    
    print_status "Backing up private key (CRITICAL)..."
    
    # Get the sealed secrets key secret
    if kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > "${backup_path}/sealed-secrets-private-key.yaml" 2>/dev/null; then
        print_success "Private key backed up successfully"
        
        # Get additional metadata
        kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath='{.items[0].metadata.name}' > "${backup_path}/private-key-name.txt" 2>/dev/null || true
        
        # Set restrictive permissions
        chmod 600 "${backup_path}/sealed-secrets-private-key.yaml"
        chmod 600 "${backup_path}/private-key-name.txt"
        
        print_warning "⚠️  PRIVATE KEY BACKED UP - Store securely!"
        print_info "This file contains the master key to decrypt ALL sealed secrets"
        
    else
        print_error "Failed to backup private key"
        return 1
    fi
}

# Backup public key (used for encryption)
backup_public_key() {
    local backup_path="$1"
    
    print_status "Backing up public key..."
    
    # Fetch public certificate
    if kubeseal --fetch-cert > "${backup_path}/sealed-secrets-public-cert.pem" 2>/dev/null; then
        print_success "Public key backed up successfully"
        
        # Set restrictive permissions
        chmod 644 "${backup_path}/sealed-secrets-public-cert.pem"
        
        print_info "Public key can be safely shared for encryption purposes"
        
    else
        print_error "Failed to backup public key"
        return 1
    fi
}

# Backup controller configuration
backup_controller_config() {
    local backup_path="$1"
    
    print_status "Backing up controller configuration..."
    
    # Backup controller deployment
    kubectl get deployment -n kube-system sealed-secrets-controller -o yaml > "${backup_path}/controller-deployment.yaml" 2>/dev/null || true
    
    # Backup controller service
    kubectl get service -n kube-system sealed-secrets -o yaml > "${backup_path}/controller-service.yaml" 2>/dev/null || true
    
    # Backup RBAC configuration
    kubectl get clusterrole sealed-secrets -o yaml > "${backup_path}/controller-clusterrole.yaml" 2>/dev/null || true
    kubectl get clusterrolebinding sealed-secrets-controller -o yaml > "${backup_path}/controller-clusterrolebinding.yaml" 2>/dev/null || true
    
    print_success "Controller configuration backed up"
}

# Create backup manifest
create_backup_manifest() {
    local backup_path="$1"
    
    print_status "Creating backup manifest..."
    
    cat > "${backup_path}/BACKUP_INFO.md" << EOF
# 🔐 Sealed Secrets Backup

**Backup Date:** $(date)
**Cluster:** ${CLUSTER_NAME}
**Backup Location:** ${backup_path}

## Files in this backup:

- \`sealed-secrets-private-key.yaml\` - **CRITICAL** Private key for decryption
- \`sealed-secrets-public-cert.pem\` - Public certificate for encryption
- \`private-key-name.txt\` - Name of the private key secret
- \`controller-*.yaml\` - Controller configuration files

## Security Notes:

⚠️  **CRITICAL:** The private key file contains the master key to decrypt ALL sealed secrets.
   - Store in secure, encrypted location
   - Limit access to authorized personnel only
   - Monitor access logs
   - Consider offsite backup for disaster recovery

✅ **Safe to share:** The public certificate can be safely shared for encryption.

## Restoration:

To restore the private key:
\`\`\`bash
kubectl apply -f sealed-secrets-private-key.yaml
kubectl delete pod -n kube-system -l name=sealed-secrets-controller
\`\`\`

To use the public key for encryption:
\`\`\`bash
kubeseal --cert=sealed-secrets-public-cert.pem -f secret.yaml -w sealed-secret.yaml
\`\`\`

## Key Rotation:

Sealed Secrets keys are automatically renewed every 30 days.
Re-run this backup script regularly to capture the latest keys.
EOF
    
    print_success "Backup manifest created"
}

# Create checksums for integrity verification
create_checksums() {
    local backup_path="$1"
    
    print_status "Creating checksums for integrity verification..."
    
    cd "${backup_path}"
    find . -type f -name "*.yaml" -o -name "*.pem" -o -name "*.txt" | while read -r file; do
        sha256sum "$file" >> "checksums.sha256"
    done
    
    print_success "Checksums created: checksums.sha256"
}

# Main backup function
main() {
    print_status "Starting Sealed Secrets backup process..."
    print_info "Cluster: ${CLUSTER_NAME}"
    print_info "Timestamp: ${TIMESTAMP}"
    
    # Check prerequisites
    check_prerequisites
    
    # Create backup directory
    backup_path=$(create_backup_directory)
    
    # Backup keys and configuration
    backup_private_key "${backup_path}" || exit 1
    backup_public_key "${backup_path}" || exit 1
    backup_controller_config "${backup_path}"
    create_backup_manifest "${backup_path}"
    create_checksums "${backup_path}"
    
    # Final summary
    echo
    print_success "🎉 Backup completed successfully!"
    print_info "Backup location: ${backup_path}"
    print_warning "⚠️  Store the private key securely!"
    print_info "📋 Review BACKUP_INFO.md for detailed instructions"
    
    # List backup contents
    echo
    print_status "Backup contents:"
    ls -la "${backup_path}/"
    
    echo
    print_info "Next steps:"
    echo "  1. Store backup in secure location (encrypted storage recommended)"
    echo "  2. Test restoration process in a non-production environment"
    echo "  3. Set up regular automated backups"
    echo "  4. Consider offsite backup for disaster recovery"
}

# Run main function
main "$@"
