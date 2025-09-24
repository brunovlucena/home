# SealedSecrets Key Backup

⚠️ **CRITICAL SECURITY WARNING** ⚠️

These files contain the cryptographic keys for SealedSecrets. They are **NEVER** committed to Git for security reasons.

## Files in this directory:

- `sealed-secrets-key-backup.yaml` - Complete SealedSecrets key secret (YAML format)
- `sealed-secrets-public-cert.pem` - Public certificate for encrypting new secrets
- `sealed-secrets-private-key.pem` - Private key for decrypting existing secrets

## Usage:

### To restore SealedSecrets keys to a new cluster:
```bash
kubectl apply -f sealed-secrets-key-backup.yaml
```

### To encrypt new secrets (use public cert):
```bash
kubeseal --format=yaml --cert=sealed-secrets-public-cert.pem < secret.yaml > sealed-secret.yaml
```

### To decrypt existing sealed secrets (use private key):
```bash
kubeseal --recovery-unseal --recovery-private-key=sealed-secrets-private-key.pem < sealed-secret.yaml
```

## Security Notes:

1. **NEVER commit these files to Git**
2. Store them securely (encrypted at rest)
3. Limit access to cluster administrators only
4. Rotate keys periodically for enhanced security
5. These keys are cluster-specific and cannot be used on other clusters

## Backup Date:
Generated on: $(date)

## Cluster:
homelab
