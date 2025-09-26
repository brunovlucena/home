# Cursor User Setup - Read-Only Kubernetes Access

This directory contains the configuration to create a Kubernetes user called "cursor" with read-only permissions. This user is designed to be used with Cursor IDE for safe Kubernetes operations without the risk of accidentally deleting resources.

## 🔒 Security Features

- ✅ **Read-only access** to all Kubernetes resources
- ✅ **Can exec into pods** for debugging purposes
- ✅ **Can view logs and metrics**
- ✅ **Can port-forward** for local development
- ❌ **CANNOT delete** any resources
- ❌ **CANNOT create** new resources
- ❌ **CANNOT modify** existing resources

## 📁 Files

- `01-serviceaccount.yaml` - Creates the cursor ServiceAccount and token secret
- `02-clusterrole.yaml` - Defines read-only permissions for the cursor role
- `03-clusterrolebinding.yaml` - Binds the cursor user to the read-only role
- `generate-cursor-kubeconfig.sh` - Script to generate the kubeconfig file
- `setup-cursor-user.sh` - Complete setup script
- `test-permissions.sh` - Script to test the cursor user permissions

## 🚀 Quick Setup

1. **Run the setup script:**
   ```bash
   ./setup-cursor-user.sh
   ```

2. **Use the generated kubeconfig:**
   ```bash
   export KUBECONFIG=$(pwd)/cursor-kubeconfig.yaml
   kubectl get pods  # This works
   kubectl delete pod <name>  # This fails (as intended)
   ```

## 🧪 Testing Permissions

Run the test script to verify the cursor user has the correct permissions:

```bash
./test-permissions.sh
```

## 💡 Usage with Cursor IDE

1. **Set the kubeconfig environment variable:**
   ```bash
   export KUBECONFIG=/path/to/cursor-kubeconfig.yaml
   ```

2. **Or use the kubeconfig flag:**
   ```bash
   kubectl --kubeconfig=/path/to/cursor-kubeconfig.yaml get pods
   ```

3. **Verify in Cursor that you can:**
   - View pods, services, deployments, etc.
   - Read logs from pods
   - Exec into pods for debugging
   - Port-forward to services

4. **Verify in Cursor that you CANNOT:**
   - Delete any resources
   - Create new resources
   - Modify existing resources

## 🔧 Customization

If you need to modify the permissions, edit the `02-clusterrole.yaml` file and reapply:

```bash
kubectl apply -f 02-clusterrole.yaml
```

## 🗑️ Cleanup

To remove the cursor user and all associated resources:

```bash
kubectl delete -f 03-clusterrolebinding.yaml
kubectl delete -f 02-clusterrole.yaml
kubectl delete -f 01-serviceaccount.yaml
rm cursor-kubeconfig.yaml
```

## 📋 Permissions Summary

The cursor user has the following permissions:

### ✅ Allowed Operations
- `get`, `list`, `watch` on most Kubernetes resources
- `create` on `pods/exec` and `pods/portforward` (for debugging)
- Access to logs, metrics, and status information

### ❌ Forbidden Operations
- `delete` - Cannot delete any resources
- `create` - Cannot create new resources (except exec/portforward)
- `update` - Cannot modify existing resources
- `patch` - Cannot patch resources

### 📦 Resource Coverage
- Core resources (pods, services, configmaps, secrets, etc.)
- Apps resources (deployments, statefulsets, etc.)
- Networking resources (ingresses, network policies)
- Batch resources (jobs, cronjobs)
- Storage resources (persistent volumes, storage classes)
- RBAC resources (roles, bindings)
- Custom resources and CRDs
- Monitoring resources (Prometheus, Grafana)
- Flux resources (GitRepository, HelmRelease, etc.)

This setup ensures you can safely use Kubernetes tools in Cursor without the risk of accidentally deleting or modifying critical resources.
