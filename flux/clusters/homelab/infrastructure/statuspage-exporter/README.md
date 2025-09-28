# Status Page Exporter

This component monitors external status pages and exposes their status as Prometheus metrics.

## Monitored Services

- **Cloudflare**: https://www.cloudflarestatus.com
- **Google Cloud Platform**: https://status.cloud.google.com
- **Amazon Web Services**: https://status.aws.amazon.com
- **Cursor**: https://status.cursor.sh
- **Claude (Anthropic)**: https://status.anthropic.com

## Metrics

The exporter provides the following metrics:

- `statuspage_component_status` - Component status (1=operational, 0=issues)
- `statuspage_fetch_duration_seconds` - Time to fetch status page
- `statuspage_up` - Whether the status page is accessible

## Alerts

The following alerts are configured:

- **ServiceStatusDown**: Triggered when a service component status is not operational
- **ServiceStatusPageDown**: Triggered when a status page is unreachable
- **ServiceStatusPageSlow**: Triggered when a status page takes more than 10 seconds to respond

## Configuration

The exporter is configured to monitor the status pages listed above. To add or remove services, update the `--statuspages` argument in the deployment.yaml file.

## Access

- **Metrics Endpoint**: `http://statuspage-exporter.statuspage-exporter.svc:9747/metrics`
- **Health Check**: `http://statuspage-exporter.statuspage-exporter.svc:9747/health`

## Troubleshooting

1. Check if the pod is running:
   ```bash
   kubectl get pods -n statuspage-exporter
   ```

2. Check the logs:
   ```bash
   kubectl logs -n statuspage-exporter deployment/statuspage-exporter
   ```

3. Check if metrics are being scraped by Prometheus:
   ```bash
   kubectl port-forward -n prometheus svc/prometheus-operated 9090:9090
   # Then visit http://localhost:9090 and search for statuspage_* metrics
   ```

## References

- [Statuspage Exporter GitHub](https://github.com/sergeyshevch/statuspage-exporter)
- [Prometheus Status Page Monitoring](https://prometheus.io/docs/guides/status-page-monitoring/)
