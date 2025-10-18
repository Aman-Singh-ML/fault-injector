# Dashboard Metrics Fix Summary

## Issues Identified

### 1. **Kafka Metrics Not Being Exported** ❌
**Problem:** Kafka message metrics were defined but never incremented.

**Root Cause:**
- **Booking Service**: The `publish_event()` function in `services/booking-service/app/api/routes/booking.py` was publishing to Kafka but NOT calling `record_kafka_message()` to track metrics.
- **Notification Service**: The Kafka consumer in `services/notification-service/app/main.py` was consuming messages but NOT tracking metrics.

**Solution Applied:**
- ✅ Updated `publish_event()` in booking service to call `record_kafka_message()` with timing
- ✅ Added Kafka metrics definitions to notification service (`kafka_messages_total`, `kafka_message_duration_seconds`)
- ✅ Updated Kafka consumer loop to track received/failed messages with duration

### 2. **Business Metrics Showing Zero** ⚠️
**Problem:** Business metrics dashboard shows "0" for all metrics.

**Root Cause:**
- Business metrics tracking IS implemented correctly in `gateway/src/metrics.js`
- The `trackBusinessMetrics()` function is called in the metrics middleware
- **However**, these metrics only increment when actual user traffic flows through specific endpoints:
  - `POST /auth/register` (status 201) → `gateway_user_registrations_total`
  - `POST /auth/login` (status 200) → `gateway_user_logins_total{status="success"}`
  - `GET /search/hotels*` → `gateway_hotel_searches_total`
  - `POST /booking/bookings` (status 201) → `gateway_booking_attempts_total{status="success"}`
  - `POST /payment/initiate` (status 201) → `gateway_payment_attempts_total{status="success"}`

**Solution:**
- ✅ Added `or vector(0)` to all dashboard queries so they show "0" instead of "No Data"
- ⚠️ **Requires user traffic** to populate - metrics are working correctly, just need actual API calls

---

## Code Changes Made

### **File 1: `services/booking-service/app/api/routes/booking.py`**
**Lines 38-54** - Updated `publish_event()` function:

```python
def publish_event(topic: str, event: dict):
    """Publish event to Kafka (optional - won't fail if Kafka unavailable)"""
    import time
    from app.metrics import record_kafka_message
    
    start_time = time.time()
    try:
        producer = get_kafka_producer()
        if producer:
            producer.send(topic, event)
            duration = time.time() - start_time
            record_kafka_message(topic=topic, status='sent', duration=duration)
            print(f"📨 Published event to Kafka: {event.get('eventType')}")
    except Exception as e:
        duration = time.time() - start_time
        record_kafka_message(topic=topic, status='failed', duration=duration)
        print(f"⚠️  Failed to publish to Kafka: {e}")
```

**Impact:** Now tracks every Kafka message sent with status ('sent' or 'failed') and duration.

---

### **File 2: `services/notification-service/app/main.py`**
**Lines 22-46** - Added Kafka metrics definitions:

```python
# Kafka metrics
kafka_messages_total = Counter(
    'notification_service_kafka_messages_total',
    'Total Kafka messages',
    ['topic', 'status']
)

kafka_message_duration_seconds = Histogram(
    'notification_service_kafka_message_duration_seconds',
    'Kafka message processing duration in seconds',
    ['topic']
)
```

**Lines 138-231** - Updated Kafka consumer to track metrics:

```python
for message in consumer:
    print(f"📬 Raw Kafka message received from topic: {message.topic}")
    start_time = time.time()
    try:
        # ... process message ...
        
        # Record successful Kafka message processing
        duration = time.time() - start_time
        kafka_messages_total.labels(topic=message.topic, status='received').inc()
        kafka_message_duration_seconds.labels(topic=message.topic).observe(duration)
        
    except Exception as e:
        # Record failed Kafka message processing
        duration = time.time() - start_time
        kafka_messages_total.labels(topic=message.topic, status='failed').inc()
        kafka_message_duration_seconds.labels(topic=message.topic).observe(duration)
        print(f"❌ Error processing Kafka message: {e}")
```

**Impact:** Now tracks every Kafka message received/failed with duration.

---

### **File 3: `helm/hotel-reservation-system/templates/observability/grafana/business-metrics-dashboard.yaml`**
**Updated all queries** to include `or vector(0)`:

```yaml
# Before:
"expr": "increase(gateway_user_registrations_total[1h])"

# After:
"expr": "increase(gateway_user_registrations_total[1h]) or vector(0)"
```

**Impact:** Dashboard now shows "0" instead of "No Data" when metrics haven't been emitted yet.

---

### **File 4: `helm/hotel-reservation-system/templates/observability/grafana/kafka-dashboard.yaml`**
**Recreated with application-level metrics** instead of Kafka JMX metrics:

```yaml
# Message Rate Panel:
- booking_service_kafka_messages_total{status="sent"}
- booking_service_kafka_messages_total{status="failed"}
- notification_service_kafka_messages_total{status="received"}
- notification_service_kafka_messages_total{status="failed"}

# Processing Duration Panel:
- booking_service_kafka_message_duration_seconds_bucket (p95, p99)

# Messages by Topic Panel:
- booking_service_kafka_messages_total{topic="booking-events"}
- notification_service_kafka_messages_total{topic="booking-events"}
```

**Impact:** Dashboard now uses application-level Kafka metrics instead of requiring Kafka JMX exporter.

---

## Deployment Steps

### **Step 1: Rebuild Docker Images**

```bash
# Rebuild booking service
cd services/booking-service
docker build -t amansingh2708/booking-service:latest .
docker push amansingh2708/booking-service:latest

# Rebuild notification service
cd ../notification-service
docker build -t amansingh2708/notification-service:latest .
docker push amansingh2708/notification-service:latest
```

### **Step 2: Deploy Updated Helm Chart**

```bash
# Upgrade Helm release
helm upgrade hotel-reservation ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --values helm/hotel-reservation-system/values.yaml \
  --wait \
  --timeout 15m

# Restart Grafana to reload dashboards
kubectl rollout restart deployment/grafana -n hotel-reservation
kubectl rollout status deployment/grafana -n hotel-reservation

# Restart services to use new images
kubectl rollout restart deployment/booking-service -n hotel-reservation
kubectl rollout restart deployment/notification-service -n hotel-reservation
```

### **Step 3: Verify Metrics Are Being Exported**

```bash
# Port-forward to services
kubectl port-forward -n hotel-reservation svc/booking-service 8000:8000
kubectl port-forward -n hotel-reservation svc/notification-service 8083:8083

# Check booking service metrics (in another terminal)
curl http://localhost:8000/metrics | grep kafka_messages_total

# Check notification service metrics
curl http://localhost:8083/metrics | grep kafka_messages_total
```

**Expected Output:**
```
# Booking Service:
booking_service_kafka_messages_total{status="sent",topic="booking-events"} 0.0
booking_service_kafka_messages_total{status="failed",topic="booking-events"} 0.0

# Notification Service:
notification_service_kafka_messages_total{status="received",topic="booking-events"} 0.0
notification_service_kafka_messages_total{status="failed",topic="booking-events"} 0.0
```

### **Step 4: Generate Test Traffic**

```bash
# Port-forward gateway
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000

# In another terminal, create a booking (this will trigger Kafka messages)
# First, register and login to get a token
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'

curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Save the token from login response, then create a booking
curl -X POST http://localhost:9000/booking/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -d '{
    "userId": "1",
    "hotelId": "hotel-123",
    "hotelName": "Test Hotel",
    "checkInDate": "2025-11-01T00:00:00Z",
    "checkOutDate": "2025-11-05T00:00:00Z",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500.00
  }'
```

### **Step 5: Verify Dashboards**

```bash
# Access Grafana
kubectl port-forward -n hotel-reservation svc/grafana 3000:3000
# Visit http://localhost:3000
# Login: admin/admin123
```

**Check these dashboards:**
1. ✅ **Kafka Monitoring** - Should show message rates after creating a booking
2. ✅ **Business Metrics** - Should show registration, login, and booking counts
3. ✅ **API Gateway** - Should show request rates
4. ✅ **Cluster Overview** - Should show service health

---

## Expected Results

### **Kafka Monitoring Dashboard:**
- **Before Fix:** All panels empty (metrics not exported)
- **After Fix:** Shows "0" initially, then increments when bookings are created
- **Metrics Tracked:**
  - Message rate (sent/received/failed)
  - Total messages
  - Processing duration (p95, p99)
  - Messages by topic

### **Business Metrics Dashboard:**
- **Before Fix:** Showed "No Data"
- **After Fix:** Shows "0" initially, increments with user activity
- **Metrics Tracked:**
  - User registrations
  - Successful logins
  - Hotel searches
  - Bookings created
  - Booking success vs failure
  - Payment success vs failure

---

## Troubleshooting

### **If Kafka metrics still show 0 after creating bookings:**

1. Check if Kafka is running:
```bash
kubectl get pods -n hotel-reservation | grep kafka
```

2. Check booking service logs:
```bash
kubectl logs -n hotel-reservation deployment/booking-service --tail=50
```

Look for: `📨 Published event to Kafka: BOOKING_CREATED`

3. Check notification service logs:
```bash
kubectl logs -n hotel-reservation deployment/notification-service --tail=50
```

Look for: `📬 Raw Kafka message received from topic: booking-events`

4. Check Prometheus targets:
```bash
kubectl port-forward -n hotel-reservation svc/prometheus 9090:9090
# Visit http://localhost:9090/targets
```

Verify `booking-service` and `notification-service` targets are UP.

### **If business metrics still show 0:**

1. Verify gateway is tracking metrics:
```bash
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
curl http://localhost:9000/metrics | grep gateway_user_registrations_total
```

2. Generate test traffic through the gateway (see Step 4 above)

3. Check that requests are reaching the gateway:
```bash
kubectl logs -n hotel-reservation deployment/gateway --tail=50
```

---

## Summary

✅ **Fixed:** Kafka metrics now being exported by booking and notification services
✅ **Fixed:** Kafka dashboard now uses application-level metrics
✅ **Fixed:** Business metrics dashboard shows "0" instead of "No Data"
⚠️ **Note:** Business and Kafka metrics require actual traffic to populate

**Next Steps:**
1. Rebuild and push Docker images
2. Deploy updated Helm chart
3. Generate test traffic
4. Verify dashboards show data

