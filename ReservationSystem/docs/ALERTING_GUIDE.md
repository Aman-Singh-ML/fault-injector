# Alerting & Monitoring Guide

This guide explains the alerting and monitoring setup for the Hotel Reservation System.

## Overview

The system includes comprehensive monitoring and alerting capabilities:

- **Prometheus** - Metrics collection and alerting engine
- **Alertmanager** - Alert routing and notification management
- **Grafana** - Visualization and dashboards
- **Jaeger** - Distributed tracing
- **Loki** - Log aggregation

## Alert Categories

### 1. Service Health Alerts

#### ServiceDown
- **Severity**: Critical
- **Trigger**: Service is unreachable for > 1 minute
- **Impact**: Service unavailable to users
- **Action**: Check pod status, logs, and recent deployments

#### GatewayDown
- **Severity**: Critical
- **Trigger**: API Gateway unreachable for > 30 seconds
- **Impact**: All API traffic affected
- **Action**: Immediate investigation required - entire system unavailable

#### AuthServiceDown
- **Severity**: Critical
- **Trigger**: Auth service unreachable for > 1 minute
- **Impact**: Users cannot login or register
- **Action**: Check database connectivity and service logs

#### BookingServiceDown
- **Severity**: Critical
- **Trigger**: Booking service unreachable for > 1 minute
- **Impact**: Users cannot make or manage bookings
- **Action**: Check database and Kafka connectivity

#### PaymentServiceDown
- **Severity**: Critical
- **Trigger**: Payment service unreachable for > 1 minute
- **Impact**: Payment processing blocked
- **Action**: Critical - check payment gateway integration

#### SearchServiceDown
- **Severity**: High
- **Trigger**: Search service unreachable for > 1 minute
- **Impact**: Users cannot search for hotels
- **Action**: Check MongoDB connectivity

#### NotificationServiceDown
- **Severity**: Warning
- **Trigger**: Notification service unreachable for > 2 minutes
- **Impact**: Users may not receive notifications
- **Action**: Check Kafka connectivity

### 2. Error Rate Alerts

#### HighErrorRate
- **Severity**: High
- **Trigger**: 5xx error rate > 5% for 5 minutes
- **Impact**: Degraded service quality
- **Action**: Check service logs for error patterns

#### CriticalErrorRate
- **Severity**: Critical
- **Trigger**: 5xx error rate > 10% for 2 minutes
- **Impact**: Severe service degradation
- **Action**: Immediate investigation - consider rollback

#### HighClientErrorRate
- **Severity**: Warning
- **Trigger**: 4xx error rate > 20% for 10 minutes
- **Impact**: Possible API contract issues
- **Action**: Check for breaking changes or client issues

### 3. Performance Alerts

#### HighResponseTime
- **Severity**: Warning
- **Trigger**: 95th percentile response time > 2 seconds for 5 minutes
- **Impact**: Slow user experience
- **Action**: Check resource utilization and database performance

#### CriticalResponseTime
- **Severity**: Critical
- **Trigger**: 95th percentile response time > 5 seconds for 2 minutes
- **Impact**: Severely degraded user experience
- **Action**: Immediate investigation - check for resource exhaustion

#### HighRequestRate
- **Severity**: Warning
- **Trigger**: Request rate > 1000 req/s for 5 minutes
- **Impact**: Possible traffic spike or DDoS
- **Action**: Monitor resource utilization, consider scaling

### 4. Resource Exhaustion Alerts

#### HighCPUUsage
- **Severity**: Warning
- **Trigger**: CPU usage > 80% for 5 minutes
- **Impact**: Performance degradation
- **Action**: Consider scaling or optimizing code

#### HighMemoryUsage
- **Severity**: Warning
- **Trigger**: Memory usage > 80% for 5 minutes
- **Impact**: Risk of OOM kills
- **Action**: Check for memory leaks, consider scaling

#### PodRestartingFrequently
- **Severity**: Warning
- **Trigger**: > 0.1 restarts per minute for 5 minutes
- **Impact**: Service instability
- **Action**: Check logs for crash reasons

#### PodCrashLooping
- **Severity**: Critical
- **Trigger**: > 0.5 restarts per minute for 5 minutes
- **Impact**: Service unavailable
- **Action**: Immediate investigation - check startup errors

### 5. Infrastructure Alerts

#### PostgresDown
- **Severity**: Critical
- **Trigger**: PostgreSQL unreachable for > 1 minute
- **Impact**: Data services unavailable
- **Action**: Check database pod and PVC status

#### HighDatabaseConnections
- **Severity**: Warning
- **Trigger**: > 80 active connections for 5 minutes
- **Impact**: Connection pool exhaustion risk
- **Action**: Check for connection leaks

#### MongoDBDown
- **Severity**: Critical
- **Trigger**: MongoDB unreachable for > 1 minute
- **Impact**: Search service unavailable
- **Action**: Check MongoDB pod status

#### RedisDown
- **Severity**: High
- **Trigger**: Redis unreachable for > 1 minute
- **Impact**: Caching unavailable, performance degraded
- **Action**: Check Redis pod status

#### KafkaDown
- **Severity**: High
- **Trigger**: Kafka unreachable for > 1 minute
- **Impact**: Event streaming unavailable
- **Action**: Check Kafka broker status

## Accessing Monitoring Tools

### Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n hotel-reservation svc/grafana 3000:3000

# Access at: http://localhost:3000
# Default credentials: admin / admin123
```

**Available Dashboards:**
- **Service Health & Failures** - Real-time service status and alerts
- **Microservices Overview** - Request rates, latency, errors
- **Business Metrics** - User registrations, bookings, payments
- **Infrastructure** - Database, cache, queue metrics

### Prometheus

```bash
# Port-forward Prometheus
kubectl port-forward -n hotel-reservation svc/prometheus 9090:9090

# Access at: http://localhost:9090
```

**Useful Queries:**
```promql
# Service uptime
up{job=~"gateway|auth-service|search-service|booking-service|payment-service|notification-service"}

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) by (job) / sum(rate(http_requests_total[5m])) by (job)

# Response time (p95)
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (job, le))

# Active alerts
ALERTS{alertstate="firing"}
```

### Alertmanager

```bash
# Port-forward Alertmanager
kubectl port-forward -n hotel-reservation svc/alertmanager 9093:9093

# Access at: http://localhost:9093
```

## Configuring Alert Notifications

### Slack Integration

1. Create a Slack webhook URL
2. Update `values.yaml`:

```yaml
observability:
  alertmanager:
    slack:
      enabled: true
      webhookUrl: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
      channel: "#alerts"
      criticalChannel: "#critical-alerts"
```

3. Upgrade Helm release:

```bash
helm upgrade --install hotel-reservation ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --values helm/hotel-reservation-system/values.yaml
```

### Email Integration

Update `values.yaml`:

```yaml
observability:
  alertmanager:
    email:
      enabled: true
      to: "team@example.com"
      from: "alertmanager@example.com"
      smarthost: "smtp.gmail.com:587"
      username: "your-email@gmail.com"
      password: "your-app-password"
```

### PagerDuty Integration

Update `values.yaml`:

```yaml
observability:
  alertmanager:
    pagerduty:
      enabled: true
      serviceKey: "your-pagerduty-service-key"
```

## Alert Routing

Alerts are routed based on severity and category:

- **Critical alerts** → Immediate notification (4h repeat)
- **High alerts** → Standard notification (6h repeat)
- **Warning alerts** → Low priority notification (12h repeat)
- **Availability alerts** → Immediate notification (2h repeat)
- **Infrastructure alerts** → Standard notification (4h repeat)

## Silencing Alerts

### Via Alertmanager UI

1. Access Alertmanager UI
2. Click "Silences" → "New Silence"
3. Add matchers (e.g., `alertname=HighCPUUsage`)
4. Set duration
5. Add comment explaining reason

### Via CLI

```bash
# Silence an alert for 2 hours
amtool silence add alertname=HighCPUUsage --duration=2h --comment="Planned maintenance"
```

## Testing Alerts

### Trigger a test alert

```bash
# Stop a service to trigger ServiceDown alert
kubectl scale deployment/search-service -n hotel-reservation --replicas=0

# Wait 1-2 minutes for alert to fire
# Check Alertmanager UI or notification channel

# Restore service
kubectl scale deployment/search-service -n hotel-reservation --replicas=1
```

## Best Practices

1. **Acknowledge alerts promptly** - Use Alertmanager silences during maintenance
2. **Review alert history** - Identify patterns and recurring issues
3. **Tune thresholds** - Adjust based on actual system behavior
4. **Document runbooks** - Add resolution steps for common alerts
5. **Test regularly** - Verify alert routing and notifications work
6. **Monitor alert fatigue** - Reduce noise by tuning or disabling low-value alerts

## Troubleshooting

### Alerts not firing

```bash
# Check Prometheus is scraping targets
kubectl logs -n hotel-reservation deployment/prometheus

# Check alert rules are loaded
curl http://localhost:9090/api/v1/rules

# Check Alertmanager connectivity
kubectl logs -n hotel-reservation deployment/alertmanager
```

### Notifications not received

```bash
# Check Alertmanager configuration
kubectl get configmap alertmanager-config -n hotel-reservation -o yaml

# Check Alertmanager logs
kubectl logs -n hotel-reservation deployment/alertmanager

# Test webhook manually
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test alert"}' \
  YOUR_SLACK_WEBHOOK_URL
```

## Additional Resources

- [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/)

