# 🔍 Hotel Reservation System - Observability Guide

This guide covers the complete observability stack implementation for the Hotel Reservation System, including distributed tracing, metrics collection, log aggregation, and visualization.

## 📋 Overview

The observability stack includes:
- **Jaeger** - Distributed tracing
- **Prometheus** - Metrics collection and alerting
- **Loki** - Log aggregation
- **Grafana** - Visualization and dashboards

## 🚀 Quick Start

### 1. Deploy with Observability

```bash
# Deploy the complete system with observability stack
helm upgrade --install hotel-reservation ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --create-namespace \
  --values helm/hotel-reservation-system/values-aks.yaml \
  --wait \
  --timeout 15m
```

### 2. Access Observability Tools

After deployment, get the external IPs:

```bash
# Get all LoadBalancer services
kubectl get svc -n observability -o wide

# Access URLs (replace with your external IPs):
# Grafana:    http://<GRAFANA_EXTERNAL_IP>:3000
# Prometheus: http://<PROMETHEUS_EXTERNAL_IP>:9090
# Jaeger:     http://<JAEGER_EXTERNAL_IP>:16686
```

### 3. Default Credentials

- **Grafana**: admin / admin123
- **Prometheus**: No authentication
- **Jaeger**: No authentication

## 📊 Dashboards

### Available Dashboards

1. **Microservices Overview**
   - Service health status
   - Request rates and response times
   - Error rates by service
   - Resource utilization

2. **Business Metrics**
   - User registrations and logins
   - Hotel searches and bookings
   - Payment success rates
   - Revenue tracking

3. **Infrastructure**
   - Database connections and performance
   - Redis memory usage
   - MongoDB operations
   - Kafka consumer lag

### Accessing Dashboards

1. Open Grafana: `http://<GRAFANA_IP>:3000`
2. Login with admin/admin123
3. Navigate to "Dashboards" → "Hotel Reservation System"

## 🔍 Distributed Tracing

### Viewing Traces

1. Open Jaeger UI: `http://<JAEGER_IP>:16686`
2. Select service from dropdown
3. Click "Find Traces"
4. Click on individual traces to see detailed spans

### Trace Correlation

Traces are automatically correlated with:
- **Logs**: Click trace ID in Grafana logs to jump to Jaeger
- **Metrics**: Service metrics are tagged with trace context
- **Errors**: Failed requests include trace IDs

## 📈 Metrics and Alerting

### Key Metrics

#### Golden Signals
- **Latency**: Response time percentiles
- **Traffic**: Request rates per service
- **Errors**: Error rates and counts
- **Saturation**: Resource utilization

#### Business Metrics
- User registration/login rates
- Hotel search volume
- Booking conversion rates
- Payment success rates
- Revenue per hour/day

#### Infrastructure Metrics
- Database connection pools
- Cache hit/miss rates
- Queue depths and processing rates
- Resource utilization (CPU, memory, disk)

### Alerting Rules

Pre-configured alerts for:
- Service downtime (>1 minute)
- High error rates (>5%)
- High response times (>2 seconds)
- Resource exhaustion (>80% CPU/memory)
- Low business KPIs (booking/payment success rates)

### Viewing Alerts

1. Open Prometheus: `http://<PROMETHEUS_IP>:9090`
2. Navigate to "Alerts" tab
3. View active alerts and their status

## 📝 Log Aggregation

### Log Structure

All services use structured JSON logging with:
- **Timestamp**: ISO 8601 format
- **Level**: DEBUG, INFO, WARN, ERROR
- **Service**: Service name
- **TraceID**: Distributed trace correlation
- **Message**: Human-readable message
- **Context**: Additional structured data

### Viewing Logs

1. Open Grafana: `http://<GRAFANA_IP>:3000`
2. Navigate to "Explore"
3. Select "Loki" as data source
4. Use LogQL queries:

```logql
# All logs from booking service
{service="booking-service"}

# Error logs across all services
{service=~".+"} |= "ERROR"

# Logs for specific trace ID
{service=~".+"} |= "trace_id=abc123"

# Logs with specific user ID
{service=~".+"} | json | user_id="12345"
```

## 🛠️ Configuration

### Environment Variables

Each service supports these observability environment variables:

```bash
# Tracing
JAEGER_ENDPOINT=http://jaeger-collector:14268/api/traces
OTEL_SERVICE_NAME=service-name
OTEL_RESOURCE_ATTRIBUTES=service.version=1.0.0

# Metrics
PROMETHEUS_ENABLED=true
METRICS_PORT=9090

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
```

### Sampling Configuration

Adjust trace sampling rates for performance:

```yaml
# In values-aks.yaml
observability:
  jaeger:
    sampling:
      type: probabilistic
      param: 0.1  # 10% sampling rate
```

## 🔧 Troubleshooting

### Common Issues

#### 1. No Metrics Appearing
```bash
# Check if services expose metrics endpoints
kubectl exec -it deployment/gateway -n hotel-reservation -- curl localhost:9090/metrics

# Verify ServiceMonitor configuration
kubectl get servicemonitor -n observability
```

#### 2. No Traces in Jaeger
```bash
# Check Jaeger collector logs
kubectl logs -f deployment/jaeger-collector -n observability

# Verify trace export configuration
kubectl logs -f deployment/gateway -n hotel-reservation | grep -i jaeger
```

#### 3. Missing Logs in Loki
```bash
# Check Promtail logs
kubectl logs -f daemonset/promtail -n observability

# Verify log format and labels
kubectl logs -f deployment/booking-service -n hotel-reservation
```

### Performance Tuning

#### Reduce Resource Usage
```yaml
# Lower sampling rates
observability:
  jaeger:
    sampling:
      param: 0.01  # 1% sampling

# Reduce retention periods
  prometheus:
    retention: 3d
  loki:
    retention: 72h
```

#### Scale for High Load
```yaml
# Increase replicas
observability:
  prometheus:
    replicas: 3
  jaeger:
    strategy: production
    collector:
      replicas: 5
```

## 📚 Best Practices

### 1. Metric Naming
- Use consistent prefixes: `service_name_metric_name`
- Include units in names: `_seconds`, `_bytes`, `_total`
- Use labels for dimensions, not metric names

### 2. Log Correlation
- Always include trace IDs in logs
- Use structured logging (JSON)
- Include relevant context (user_id, request_id)

### 3. Alert Fatigue Prevention
- Set appropriate thresholds
- Use alert grouping and routing
- Implement escalation policies

### 4. Dashboard Design
- Focus on user journey and business metrics
- Use consistent time ranges
- Include SLI/SLO tracking

## 🔗 Additional Resources

- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/)
- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Jaeger Tracing Best Practices](https://www.jaegertracing.io/docs/latest/best-practices/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
