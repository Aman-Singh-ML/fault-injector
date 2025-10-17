# Troubleshooting Alerts Guide

## Quick Diagnostics

### 1. Check Prometheus Targets

Access Prometheus UI and verify all services are being scraped:

```bash
kubectl port-forward -n hotel-reservation svc/prometheus 9090:9090
```

Then open: http://localhost:9090/targets

**Expected targets:**
- gateway
- auth-service
- search-service
- booking-service
- payment-service
- notification-service
- postgres (if metrics exporter is enabled)
- mongodb (if metrics exporter is enabled)
- redis (if metrics exporter is enabled)
- kafka (if metrics exporter is enabled)

**Status should be "UP" for all targets**

### 2. Check Active Alerts

In Prometheus UI, go to: http://localhost:9090/alerts

This shows:
- Which alerts are firing
- Why they're firing (the expression value)
- How long they've been firing

### 3. Verify Metrics Exist

In Prometheus UI, go to: http://localhost:9090/graph

Try these queries to verify metrics are being collected:

```promql
# Check if services are up
up{job=~"gateway|auth-service|search-service|booking-service|payment-service|notification-service"}

# Check if HTTP metrics exist
http_requests_total

# Check if duration metrics exist
http_request_duration_seconds_bucket

# Check request rate
rate(http_requests_total[5m])
```

## Common Issues and Solutions

### Issue 1: ServiceDown Alerts but Services are Running

**Cause:** Prometheus can't scrape the service metrics endpoint

**Solutions:**

1. **Check if services expose metrics:**

```bash
# For Node.js (Gateway)
kubectl exec -n hotel-reservation deployment/gateway -- curl localhost:9000/metrics

# For Python services (Booking, Notification)
kubectl exec -n hotel-reservation deployment/booking-service -- curl localhost:8000/metrics

# For Go services (Search, Payment)
kubectl exec -n hotel-reservation deployment/search-service -- curl localhost:8081/metrics

# For Java (Auth)
kubectl exec -n hotel-reservation deployment/auth-service -- curl localhost:8080/actuator/prometheus
```

2. **Check Prometheus scrape configuration:**

```bash
kubectl get configmap prometheus-config -n hotel-reservation -o yaml
```

Verify the `scrape_configs` section has entries for all services.

3. **Check service discovery:**

```bash
# Verify services exist
kubectl get svc -n hotel-reservation

# Verify endpoints are ready
kubectl get endpoints -n hotel-reservation
```

### Issue 2: HighErrorRate Alerts

**Cause:** Services are returning 5xx errors

**Solutions:**

1. **Check service logs:**

```bash
kubectl logs -n hotel-reservation deployment/gateway --tail=100
kubectl logs -n hotel-reservation deployment/booking-service --tail=100
kubectl logs -n hotel-reservation deployment/payment-service --tail=100
```

2. **Check for common issues:**
   - Database connection failures
   - Missing environment variables
   - Kafka/Redis connectivity issues
   - Authentication failures

3. **Query error details in Prometheus:**

```promql
# Error rate by service
sum(rate(http_requests_total{status=~"5.."}[5m])) by (job, status)

# Error rate by endpoint
sum(rate(http_requests_total{status=~"5.."}[5m])) by (job, path)
```

### Issue 3: Metrics Not Available

**Cause:** Services don't have metrics instrumentation

**For each service type:**

#### Node.js (Gateway)

Check if `prom-client` is installed and metrics are exposed:

```javascript
// Should have in index.js or similar
const promClient = require('prom-client');
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

#### Python (Booking, Notification)

Check if `prometheus-client` or `prometheus-fastapi-instrumentator` is installed:

```python
# Should have in main.py
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()
Instrumentator().instrument(app).expose(app)
```

#### Go (Search, Payment)

Check if Prometheus metrics are exposed:

```go
// Should have in main.go
import "github.com/prometheus/client_golang/prometheus/promhttp"

http.Handle("/metrics", promhttp.Handler())
```

#### Java (Auth Service)

Check if Spring Boot Actuator is configured:

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
  metrics:
    export:
      prometheus:
        enabled: true
```

### Issue 4: Alert Rules Not Loading

**Symptoms:** No alerts showing in Prometheus UI

**Solutions:**

1. **Check if alert rules ConfigMap exists:**

```bash
kubectl get configmap prometheus-alert-rules -n hotel-reservation
```

2. **Check Prometheus logs for rule loading errors:**

```bash
kubectl logs -n hotel-reservation deployment/prometheus | grep -i "error\|rule"
```

3. **Verify alert rules are mounted:**

```bash
kubectl describe deployment prometheus -n hotel-reservation | grep -A 5 "Mounts:"
```

4. **Check Prometheus configuration:**

```bash
kubectl exec -n hotel-reservation deployment/prometheus -- cat /etc/prometheus/prometheus.yml | grep -A 5 "rule_files"
```

### Issue 5: Alertmanager Not Receiving Alerts

**Symptoms:** Alerts firing in Prometheus but not in Alertmanager

**Solutions:**

1. **Check Alertmanager is running:**

```bash
kubectl get pods -n hotel-reservation -l app.kubernetes.io/name=alertmanager
```

2. **Check Prometheus → Alertmanager connectivity:**

```bash
# In Prometheus UI, check: http://localhost:9090/config
# Look for alerting.alertmanagers section
```

3. **Check Alertmanager logs:**

```bash
kubectl logs -n hotel-reservation deployment/alertmanager
```

4. **Verify Alertmanager configuration:**

```bash
kubectl get configmap alertmanager-config -n hotel-reservation -o yaml
```

## Temporarily Disable Alerts

If you want to silence alerts during testing or maintenance:

### Option 1: Silence in Alertmanager UI

```bash
kubectl port-forward -n hotel-reservation svc/alertmanager 9093:9093
```

Open http://localhost:9093 and create silences.

### Option 2: Disable alert rules temporarily

```bash
# Edit values.yaml and set:
observability:
  alertmanager:
    enabled: false

# Then upgrade:
helm upgrade hotel-reservation ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --values helm/hotel-reservation-system/values.yaml
```

### Option 3: Adjust alert thresholds

Edit `helm/hotel-reservation-system/templates/observability/prometheus/alert-rules.yaml` and adjust:
- `for:` duration (how long before alert fires)
- `expr:` threshold values (e.g., change `> 0.05` to `> 0.10`)

## Verifying Metrics Collection

Run these commands to verify each service is exposing metrics:

```bash
# Gateway (Node.js)
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
curl http://localhost:9000/metrics

# Auth Service (Java)
kubectl port-forward -n hotel-reservation svc/auth-service 8080:8080
curl http://localhost:8080/actuator/prometheus

# Search Service (Go)
kubectl port-forward -n hotel-reservation svc/search-service 8081:8081
curl http://localhost:8081/metrics

# Booking Service (Python)
kubectl port-forward -n hotel-reservation svc/booking-service 8000:8000
curl http://localhost:8000/metrics

# Payment Service (Go)
kubectl port-forward -n hotel-reservation svc/payment-service 8082:8082
curl http://localhost:8082/metrics

# Notification Service (Python)
kubectl port-forward -n hotel-reservation svc/notification-service 8083:8083
curl http://localhost:8083/metrics
```

## Expected Metrics

Each service should expose these metrics:

### Common Metrics (all services)
- `up` - Service health (1 = up, 0 = down)
- `http_requests_total` - Total HTTP requests
- `http_request_duration_seconds` - Request latency histogram
- `process_cpu_seconds_total` - CPU usage
- `process_resident_memory_bytes` - Memory usage

### Service-Specific Metrics

**Gateway:**
- `http_requests_total{method, path, status}`
- `http_request_duration_seconds{method, path}`

**Auth Service:**
- `http_server_requests_seconds_count`
- `http_server_requests_seconds_sum`
- `jvm_memory_used_bytes`

**Booking Service:**
- `http_requests_total{method, path, status}`
- `booking_created_total`
- `booking_cancelled_total`

**Payment Service:**
- `http_requests_total{method, path, status}`
- `payment_processed_total`
- `payment_failed_total`

## Next Steps

1. **Identify which alerts are firing** - Check Prometheus alerts page
2. **Verify metrics exist** - Run the queries above
3. **Check service logs** - Look for errors or warnings
4. **Add missing instrumentation** - If metrics don't exist, add them to services
5. **Tune alert thresholds** - Adjust based on actual system behavior

## Getting Help

If alerts persist:
1. Share the output of: `kubectl get pods -n hotel-reservation`
2. Share which alerts are firing from Prometheus UI
3. Share the output of the metrics verification commands above
4. Share relevant service logs

