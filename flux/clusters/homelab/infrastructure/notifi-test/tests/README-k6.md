# k6 Test Suite for Notifi Mock Infrastructure

This directory contains k6 performance tests that translate the Kubernetes test suite from `tests.yaml` into comprehensive load testing scenarios.

## Overview

The k6 test suite provides:
- **Performance Testing**: Load testing for all service types
- **Integration Testing**: Comprehensive end-to-end testing
- **Health Monitoring**: Continuous health checks
- **Network Policy Testing**: Security and connectivity validation
- **Metrics Collection**: Performance metrics gathering

## Files

- `k6-tests.js` - Main k6 test file with all test scenarios
- `k6-config.json` - k6 configuration with different test scenarios
- `README-k6.md` - This documentation file

## Test Scenarios

### 1. Service-Specific Tests
- **Gateway Tests**: Management and Dataplane gateways
- **Manager Tests**: All manager services (user, template, tenant, etc.)
- **Messenger Tests**: All messenger services (mailer, SMS, Telegram, etc.)
- **Proxy Tests**: All proxy services (EVM, Solana, Aptos, etc.)
- **Database Tests**: ClickHouse and Redis connectivity
- **Monitoring Tests**: Monitor service health and metrics
- **Processor Tests**: Event processor functionality
- **Handler Tests**: Callback handler functionality
- **Service Tests**: Outpost service and other components
- **gRPC Server Tests**: gRPC server health and metrics
- **WebSocket Tests**: WebSocket server functionality

### 2. Load Testing Scenarios
- **Gateway Load Tests**: High-volume testing of gateway services
- **Manager Load Tests**: Stress testing of manager services
- **Messenger Load Tests**: Load testing of messenger services

### 3. Integration Tests
- **Comprehensive Integration**: End-to-end testing of all services
- **Network Policy Tests**: Security and connectivity validation
- **Health Checks**: Continuous monitoring of service health
- **Metrics Collection**: Performance metrics gathering

## Running the Tests

### Prerequisites
```bash
# Install k6
# On macOS
brew install k6

# On Ubuntu/Debian
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6A1AED5
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# On Windows
choco install k6
```

### Basic Usage

#### Run All Tests
```bash
k6 run k6-tests.js
```

#### Run with Custom Configuration
```bash
k6 run --config k6-config.json k6-tests.js
```

#### Run Specific Test Scenarios
```bash
# Run only gateway tests
k6 run --exec testGateways k6-tests.js

# Run only integration tests
k6 run --exec testIntegration k6-tests.js

# Run only load tests
k6 run --exec loadTestGateways k6-tests.js
```

#### Run with Custom Load Profile
```bash
# Light load (5 users for 2 minutes)
k6 run --vus 5 --duration 2m k6-tests.js

# Heavy load (50 users for 5 minutes)
k6 run --vus 50 --duration 5m k6-tests.js

# Spike test (ramp up to 100 users)
k6 run --stage 30s:10,1m:100,30s:0 k6-tests.js
```

### Advanced Usage

#### Run with Custom Thresholds
```bash
k6 run --threshold http_req_duration=p(95)<200 k6-tests.js
```

#### Run with Custom Metrics
```bash
k6 run --out json=results.json k6-tests.js
```

#### Run in Kubernetes
```bash
# Create a k6 job in Kubernetes
kubectl create job k6-test --image=grafana/k6:latest -- k6 run /scripts/k6-tests.js
```

## Test Configuration

### Load Testing Profiles

#### Light Load
- 5-10 virtual users
- 2-5 minute duration
- Suitable for development testing

#### Medium Load
- 20-50 virtual users
- 5-10 minute duration
- Suitable for staging testing

#### Heavy Load
- 100+ virtual users
- 10+ minute duration
- Suitable for production testing

### Thresholds

The tests include the following performance thresholds:
- **Response Time**: 95% of requests must complete under 500ms
- **Error Rate**: Less than 10% of requests should fail
- **Custom Metrics**: Error rate and response time tracking

## Service Endpoints

### Gateway Services
- Management Gateway: `http://mock-management-gateway:5000`
- Dataplane Gateway: `http://mock-dataplane-gateway:80`

### Manager Services
- User Manager: `http://mock-user-manager:4000`
- Template Manager: `http://mock-template-manager:4000`
- Tenant Manager: `http://mock-tenant-manager:4000`
- Blockchain Manager: `http://mock-blockchain-manager:4000`
- Chat Manager: `http://mock-chat-manager:4000`
- Storage Manager: `http://mock-storage-manager:4000`
- Fusion Manager: `http://mock-fusion-manager:4000`
- Subscription Manager: `http://mock-subscription-manager:4000`
- Points Manager: `http://mock-points-manager:4000`
- Scheduler: `http://mock-scheduler:4000`
- Rate Limit Broker: `http://mock-rate-limit-broker:4000`

### Messenger Services
- Mailer: `http://mock-mailer:5000`
- SMS Messenger: `http://mock-sms-messenger:5000`
- Telegram Messenger: `http://mock-telegram-messenger:5000`
- FCM Messenger: `http://mock-fcm-messenger:5000`
- Discord Messenger: `http://mock-discord-messenger:5000`
- Slack Channel Messenger: `http://mock-slack-channel-messenger:5000`
- Web Push Messenger: `http://mock-web-push-messenger:5000`
- Web3 Messenger: `http://mock-web3-messenger:5000`
- Webhook Sender: `http://mock-webhook-sender:5000`

### Proxy Services
- EVM Proxy: `http://mock-evm-proxy:7000`
- Solana Proxy: `http://mock-solana-proxy:7000`
- Aptos Proxy: `http://mock-aptos-proxy:7000`
- SUI Proxy: `http://mock-sui-proxy:7000`
- Cosmos Proxy: `http://mock-cosmos-proxy:7000`
- BTC Proxy: `http://mock-btc-proxy:7000`
- XMTP Proxy: `http://mock-xmtp-proxy:5000`
- RPC Proxy: `http://mock-rpc-proxy:80`
- Fetch Proxy: `http://mock-fetch-proxy:4000`

### Database Services
- ClickHouse: `http://mock-clickhouse:8123`
- ClickHouse Native: `http://mock-clickhouse:9000`

### Monitoring Services
- Monitor: `http://mock-monitor:5000`

### Processor Services
- Event Processor: `http://mock-event-processor:5000`

### Handler Services
- Callback Handler: `http://mock-callback-handler:5000`

### Service Components
- Outpost Service: `http://mock-outpost-service:5000`

### gRPC Server Services
- gRPC Server: Health and metrics endpoints

### WebSocket Server Services
- WebSocket Server: Health and metrics endpoints

## Test Results

### Metrics Collected
- **HTTP Request Duration**: Response time for all requests
- **HTTP Request Rate**: Requests per second
- **HTTP Request Failures**: Failed request rate
- **Custom Error Rate**: Application-specific error rate
- **Custom Response Time**: Service-specific response time

### Output Formats
- **Console Output**: Real-time test progress and results
- **JSON Output**: Structured results for analysis
- **InfluxDB Output**: Time-series data for Grafana dashboards
- **CloudWatch Output**: AWS CloudWatch integration

## Continuous Integration

### GitHub Actions Example
```yaml
name: k6 Performance Tests
on: [push, pull_request]
jobs:
  performance-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install k6
        run: |
          sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6A1AED5
          echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update
          sudo apt-get install k6
      - name: Run k6 tests
        run: k6 run tests/k6-tests.js
```

## Troubleshooting

### Common Issues

1. **Connection Refused**: Ensure all mock services are running
2. **Timeout Errors**: Check network connectivity and service health
3. **High Error Rates**: Verify service configurations and resource limits
4. **Memory Issues**: Adjust k6 memory limits for large test scenarios

### Debug Mode
```bash
# Run with verbose output
k6 run --verbose k6-tests.js

# Run with debug logging
k6 run --log-output=file=debug.log k6-tests.js
```

### Performance Tuning
```bash
# Reduce memory usage
k6 run --max-redirects 10 k6-tests.js

# Optimize for high load
k6 run --batch 20 k6-tests.js
```

## Contributing

When adding new tests:
1. Follow the existing service configuration pattern
2. Add appropriate thresholds and metrics
3. Include both positive and negative test cases
4. Document new service endpoints
5. Update this README with new test scenarios
