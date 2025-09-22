# 🔐 Sealed Secrets Backup and Restore Guide

This guide explains how to safely backup and restore Sealed Secrets keys to prevent accidental deletion and ensure disaster recovery capability.

## 🚨 Critical Security Information

**⚠️ IMPORTANT:** The private key is the master key that can decrypt ALL sealed secrets in your cluster. Handle it with extreme care!

- **Never commit backup files to Git** (they're already in `.gitignore`)
- **Store backups in encrypted storage**
- **Limit access to authorized personnel only**
- **Monitor access logs**
- **Consider offsite backup for disaster recovery**

## 📋 Prerequisites

Before running backup/restore operations, ensure you have:

- `kubectl` installed and configured
- `kubeseal` CLI tool installed:
  ```bash
  # macOS
  brew install kubeseal
  
  # Linux
  # Download from https://github.com/bitnami-labs/sealed-secrets/releases
  ```
- Access to the Kubernetes cluster
- Sealed Secrets controller running

## 🔄 Backup Process

### 1. Run the Backup Script

```bash
# Navigate to the sealed-secrets directory
cd flux/clusters/studio/infrastructure/sealed-secrets

# Run the backup script
./backup-sealed-secrets-keys.sh
```

### 2. Customize Backup Location (Optional)

```bash
# Set custom backup directory
export BACKUP_DIR="/secure/backup/location"
export CLUSTER_NAME="production"

./backup-sealed-secrets-keys.sh
```

### 3. What Gets Backed Up

The script creates a timestamped backup directory containing:

- **`sealed-secrets-private-key.yaml`** - 🔴 **CRITICAL** Private key for decryption
- **`sealed-secrets-public-cert.pem`** - 🟢 Public certificate for encryption
- **`private-key-name.txt`** - Name of the private key secret
- **`controller-*.yaml`** - Controller configuration files
- **`BACKUP_INFO.md`** - Detailed backup information
- **`checksums.sha256`** - Integrity verification checksums

### 4. Example Output

```
🔧 Checking prerequisites...
✅ All prerequisites met
🔧 Creating backup directory...
✅ Backup directory created: ./backups/studio_20241215_143022
🔧 Backing up private key (CRITICAL)...
✅ Private key backed up successfully
⚠️  PRIVATE KEY BACKED UP - Store securely!
ℹ️  This file contains the master key to decrypt ALL sealed secrets
🔧 Backing up public key...
✅ Public key backed up successfully
ℹ️  Public key can be safely shared for encryption purposes
🔧 Backing up controller configuration...
✅ Controller configuration backed up
🔧 Creating backup manifest...
✅ Backup manifest created
🔧 Creating checksums for integrity verification...
✅ Checksums created: checksums.sha256

🎉 Backup completed successfully!
ℹ️  Backup location: ./backups/studio_20241215_143022
⚠️  Store the private key securely!
ℹ️  📋 Review BACKUP_INFO.md for detailed instructions
```

## 🔄 Restore Process

### 1. Run the Restore Script

```bash
# Restore from specific backup directory
./restore-sealed-secrets-keys.sh ./backups/studio_20241215_143022

# Skip confirmation prompts (use with caution)
./restore-sealed-secrets-keys.sh ./backups/studio_20241215_143022 --force
```

### 2. What the Restore Process Does

1. **Validates backup directory** and required files
2. **Verifies backup integrity** using checksums
3. **Checks current cluster status** for existing keys
4. **Prompts for confirmation** (unless `--force` is used)
5. **Restores the private key** to the cluster
6. **Restarts the controller** to load the restored keys
7. **Verifies restoration** by testing key functionality
8. **Tests with sample secret** to ensure everything works

### 3. Example Output

```
🔧 Checking prerequisites...
✅ All prerequisites met
🔧 Validating backup directory...
🔧 Verifying backup integrity...
✅ Backup integrity verified
✅ Backup directory validated
🔧 Checking current sealed secrets status...
ℹ️  Sealed Secrets controller is currently running
⚠️  Sealed secrets keys already exist in the cluster!
⚠️  This will overwrite the existing keys.

⚠️  WARNING: This will restore sealed secrets keys to your cluster
ℹ️  Backup directory: ./backups/studio_20241215_143022

⚠️  CRITICAL: Sealed secrets keys already exist!
⚠️  This operation will OVERWRITE existing keys.
⚠️  All existing sealed secrets may become inaccessible if this is the wrong backup!

Are you sure you want to proceed? (yes/no): yes

🔧 Restoring private key...
✅ Private key restored successfully
🔧 Restarting Sealed Secrets controller...
✅ Controller pod deleted
🔧 Waiting for controller to be ready...
✅ Controller is ready
🔧 Verifying restoration...
✅ Restoration verified successfully
🔧 Testing restoration with sample secret...
✅ Sample secret sealing test passed

🎉 Restoration completed successfully!
ℹ️  Sealed secrets keys have been restored and verified
⚠️  Note: Previous keys were overwritten
```

## 🔒 Security Best Practices

### Storage Security

- **Encrypt backup files** before storing
- **Use secure storage locations** (encrypted drives, secure cloud storage)
- **Implement access controls** and audit logging
- **Store multiple copies** in different locations
- **Test restoration regularly** in non-production environments

### Access Control

- **Limit access** to backup files to essential personnel only
- **Use strong authentication** for backup storage systems
- **Monitor access logs** for unauthorized access attempts
- **Implement principle of least privilege**

### Backup Frequency

- **Backup immediately** after any sealed secrets configuration changes
- **Regular automated backups** (daily/weekly depending on your needs)
- **Backup before cluster upgrades** or major changes
- **Backup before key rotations** (every 30 days)

## 🤖 Automation

### Automated Backup Script

Create a cron job for regular backups:

```bash
# Add to crontab for daily backups at 2 AM
0 2 * * * /path/to/sealed-secrets/backup-sealed-secrets-keys.sh
```

### Backup to Cloud Storage

```bash
#!/bin/bash
# Enhanced backup script with cloud upload
BACKUP_DIR="/tmp/sealed-secrets-backup"
CLOUD_BUCKET="s3://your-secure-backup-bucket"

# Run backup
./backup-sealed-secrets-keys.sh

# Upload to secure cloud storage
aws s3 cp --recursive --sse AES256 "$BACKUP_DIR" "$CLOUD_BUCKET/sealed-secrets/"

# Clean up local backup
rm -rf "$BACKUP_DIR"
```

## 🚨 Disaster Recovery

### Recovery Scenarios

1. **Accidental Key Deletion**
   - Use the most recent backup
   - Run restore script immediately
   - Verify all sealed secrets are accessible

2. **Cluster Recreation**
   - Restore sealed secrets keys first
   - Apply all sealed secret manifests
   - Verify application functionality

3. **Key Corruption**
   - Restore from backup
   - Test with sample secrets
   - Update applications if needed

### Recovery Testing

Regularly test your recovery process:

```bash
# Create test cluster
kind create cluster --name test-recovery

# Install sealed secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Test restore process
./restore-sealed-secrets-keys.sh ./backups/latest-backup

# Clean up
kind delete cluster --name test-recovery
```

## 🔍 Troubleshooting

### Common Issues

#### Backup Script Fails

```bash
# Check if sealed secrets controller is running
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Check if kubeseal is installed
kubeseal --version

# Check cluster connectivity
kubectl cluster-info
```

#### Restore Script Fails

```bash
# Check backup directory contents
ls -la ./backups/studio_20241215_143022/

# Verify backup integrity
cd ./backups/studio_20241215_143022/
sha256sum -c checksums.sha256

# Check cluster permissions
kubectl auth can-i create secrets -n kube-system
```

#### Controller Won't Start

```bash
# Check controller logs
kubectl logs -n kube-system -l name=sealed-secrets-controller

# Check for RBAC issues
kubectl get clusterrole sealed-secrets
kubectl get clusterrolebinding sealed-secrets-controller

# Restart controller manually
kubectl delete pod -n kube-system -l name=sealed-secrets-controller
```

## 📚 Additional Resources

- [Sealed Secrets Documentation](https://github.com/bitnami-labs/sealed-secrets)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Flux CD Documentation](https://fluxcd.io/)

## 🆘 Emergency Contacts

In case of critical issues:

1. **Check cluster status** and controller logs
2. **Verify backup integrity** and availability
3. **Test restore process** in non-production environment
4. **Contact cluster administrators** if needed

---

**Remember:** The private key is your lifeline for sealed secrets. Protect it with the same level of security as your most sensitive data!
