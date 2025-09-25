# k6-operator

This directory contains the configuration for the k6-operator, which enables distributed performance testing in Kubernetes using k6.

## Overview

The k6-operator allows you to run k6 performance tests as Kubernetes resources, enabling distributed testing across multiple pods. This is particularly useful for load testing your applications at scale.

## Components

- **namespace.yaml**: Creates the `k6-operator` namespace
- **helmrelease.yaml**: Deploys the k6-operator using the Grafana Helm chart
- **example-test-configmap.yaml**: Example ConfigMap containing a k6 test script
- **example-testrun.yaml**: Example TestRun resource for running k6 tests

## Usage

### 1. Deploy the k6-operator

The operator is automatically deployed via Flux when you apply the infrastructure:

```bash
# The operator will be deployed automatically via Flux
kubectl get pods -n k6-operator
```

### 2. Create a k6 test script

Create a ConfigMap containing your k6 test script:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-k6-test
  namespace: notifi-test
data:
  test.js: |
    import http from 'k6/http';
    import { check } from 'k6';

    export default function () {
      const res = http.get('https://test-api.example.com');
      check(res, {
        'is status 200': (r) => r.status === 200,
      });
    }
```

### 3. Create a TestRun resource

Create a TestRun resource to execute your test:

```yaml
apiVersion: k6.io/v1alpha1
kind: TestRun
metadata:
  name: my-k6-test-run
  namespace: notifi-test
spec:
  parallelism: 4
  script:
    configMap:
      name: my-k6-test
      file: test.js
  runner:
    image: grafana/k6:latest
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 100m
        memory: 128Mi
  starter:
    image: grafana/k6:latest
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
      requests:
        cpu: 50m
        memory: 64Mi
  arguments: |
    --vus=10
    --duration=2m
    --out=json=test-results.json
  cleanup: "onSuccess"
```

### 4. Apply the resources

```bash
kubectl apply -f example-test-configmap.yaml
kubectl apply -f example-testrun.yaml
```

### 5. Monitor the test

```bash
# Check the status of the test
kubectl get testruns -n notifi-test

# View the test logs
kubectl logs -n notifi-test -l k6.io/testrun=notifi-infrastructure-test

# Check the test results
kubectl get pods -n notifi-test -l k6.io/testrun=notifi-infrastructure-test
```

## Example Test

The included example test (`example-test-configmap.yaml` and `example-testrun.yaml`) demonstrates how to test the Notifi mock infrastructure services. It includes:

- Gateway services testing
- Manager services testing
- Messenger services testing
- Proxy services testing
- Database services testing
- Monitoring services testing
- Processor services testing
- Handler services testing
- gRPC and WebSocket server testing

## Configuration

The k6-operator is configured with the following settings:

- **Version**: 1.0.0 (latest stable)
- **Namespace**: k6-operator
- **Resources**: Optimized for low resource usage
- **Security**: Runs with non-root user
- **Monitoring**: ServiceMonitor enabled for Prometheus metrics

## Troubleshooting

### Check operator status
```bash
kubectl get pods -n k6-operator
kubectl logs -n k6-operator -l app.kubernetes.io/name=k6-operator
```

### Check test run status
```bash
kubectl get testruns -n notifi-test
kubectl describe testrun -n notifi-test <testrun-name>
```

### View test logs
```bash
kubectl logs -n notifi-test -l k6.io/testrun=<testrun-name>
```

## Resources

- [k6-operator Documentation](https://github.com/grafana/k6-operator)
- [k6 Documentation](https://k6.io/docs/)
- [Grafana k6-operator Helm Chart](https://github.com/grafana/k6-operator/tree/main/charts/k6-operator)
