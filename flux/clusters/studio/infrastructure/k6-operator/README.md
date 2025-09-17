# K6 Operator

This directory contains the K6 Operator setup for load testing the Bruno Site.

## Components

- **Namespace**: `k6-operator` - Dedicated namespace for k6 resources
- **HelmRelease**: Deploys the k6-operator from Grafana Helm repository
- **ConfigMap**: Contains the load test script for Bruno Site
- **K6 Test**: Custom resource that defines the load test configuration

## Usage

### Deploy the k6-operator

The k6-operator will be automatically deployed by Flux when this directory is applied.

### Run a load test

```bash
# Apply the k6 test
kubectl apply -f k6-test.yaml

# Check the test status
kubectl get k6 -n k6-operator

# View test logs
kubectl logs -n k6-operator -l k6_cr=bruno-site-load-test

# Delete the test when done
kubectl delete k6 bruno-site-load-test -n k6-operator
```

### Test Configuration

The load test includes:
- Health check endpoint
- Projects API endpoint
- About API endpoint  
- Contact API endpoint
- Chat API endpoint (POST)

### Performance Thresholds

- 95% of requests must complete below 500ms
- Error rate must be less than 10%
- Health check response time < 200ms
- Projects response time < 500ms
- About/Contact response time < 300ms
- Chat response time < 2000ms

### Test Stages

1. **Ramp up**: 30 seconds to reach 5 virtual users
2. **Sustain**: 1 minute at 5 virtual users
3. **Ramp down**: 30 seconds to 0 virtual users

## Resources

- [K6 Operator Documentation](https://k6.io/docs/testing-guides/running-k6-operator/)
- [K6 Test Configuration](https://k6.io/docs/using-k6/k6-options/)
