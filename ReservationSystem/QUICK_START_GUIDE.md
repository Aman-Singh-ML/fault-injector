# 🚀 Quick Start Guide - Hotel Reservation System

## 📋 **Table of Contents**
1. [Starting the System](#starting-the-system)
2. [Testing the System](#testing-the-system)
3. [Implementing Remaining Features](#implementing-remaining-features)
4. [Troubleshooting](#troubleshooting)

---

## 🎯 **Starting the System**

### **Step 1: Start Infrastructure** (Docker Compose)
```bash
# Start all infrastructure services
docker-compose -f docker-compose-infrastructure.yml up -d

# Verify all services are running
docker-compose -f docker-compose-infrastructure.yml ps

# Expected output:
# ✅ hotel-postgres-auth (port 5432)
# ✅ hotel-postgres-booking (port 5433)
# ✅ hotel-postgres-payment (port 5434)
# ✅ hotel-mongo (port 27017)
# ✅ hotel-redis (port 6379)
# ✅ hotel-kafka (ports 9092/9093)
# ✅ hotel-rabbitmq (ports 5672/15672)
# ✅ hotel-zookeeper (port 2181)
```

### **Step 2: Start Microservices**

**Terminal 1 - API Gateway**:
```bash
cd gateway
npm install  # First time only
npm start
# Expected: 🚀 API Gateway running on port 9000
```

**Terminal 2 - Search Service** (Go):
```bash
cd services/search-service
PORT=8081 go run cmd/main.go
# Expected: Search service running on port 8081
```

**Terminal 3 - Booking Service** (Python):
```bash
cd services/booking-service
python3 -m app.main
# Expected: Uvicorn running on http://0.0.0.0:8000
```

**Terminal 4 - Payment Service** (Go):
```bash
cd services/payment-service
go run cmd/main.go
# Expected: Payment service running on port 8082
```

**Terminal 5 - Notification Service** (Python):
```bash
cd services/notification-service
python3 -m app.main
# Expected: Uvicorn running on http://0.0.0.0:8083
```

---

## 🧪 **Testing the System**

### **Quick Health Check**:
```bash
echo "=== System Health Check ===" && \
echo "1. Gateway:" && curl -s http://localhost:9000/health | python3 -m json.tool | head -5 && \
echo "2. Search:" && curl -s http://localhost:8081/health && echo "" && \
echo "3. Booking:" && curl -s http://localhost:8000/health && echo "" && \
echo "4. Payment:" && curl -s http://localhost:8082/health && echo "" && \
echo "5. Notification:" && curl -s http://localhost:8083/health && echo ""
```

### **Full Workflow Test**:
```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")

echo "✅ Login successful: $TOKEN"

# 2. Search Hotels
curl -s -X GET "http://localhost:9000/search/hotels" \
  -H "Authorization: Bearer $TOKEN" | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'✅ Found {len(data)} hotels')"

# 3. Create Booking
BOOKING=$(curl -s -X POST http://localhost:9000/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "5",
    "hotelId": "hotel_001",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-10-20",
    "checkOutDate": "2025-10-22",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500
  }')

BOOKING_ID=$(echo $BOOKING | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
echo "✅ Booking created: $BOOKING_ID"

# 4. Check Availability (with Redis cache)
curl -s -X GET "http://localhost:9000/booking/availability/check?hotel_id=hotel_001&check_in=2025-10-20&check_out=2025-10-22&rooms=1" \
  -H "Authorization: Bearer $TOKEN" | \
  python3 -m json.tool

# 5. Get Notifications
curl -s http://localhost:8083/notifications/5 | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'✅ Notifications: {data[\"unreadCount\"]} unread')"
```

### **Admin Panel Test**:
```bash
# Login as admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hotel.com","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")

# Get analytics
curl -s http://localhost:9000/auth/admin/analytics \
  -H "Authorization: Bearer $ADMIN_TOKEN" | \
  python3 -m json.tool

# Get all hotels
curl -s http://localhost:9000/admin/hotels \
  -H "Authorization: Bearer $ADMIN_TOKEN" | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'✅ Total hotels: {data[\"total\"]}')"
```

---

## 🔧 **Implementing Remaining Features**

### **Feature 3: Kafka Extended Topics** (2 hours)

**Step 1: Create new Kafka topics**:
```bash
# Create user-events topic
docker exec hotel-kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic user-events \
  --partitions 3 \
  --replication-factor 1

# Create hotel-updates topic
docker exec hotel-kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic hotel-updates \
  --partitions 3 \
  --replication-factor 1

# Verify topics
docker exec hotel-kafka kafka-topics --list \
  --bootstrap-server localhost:9092
```

**Step 2: Update Auth Service** (Java - publish user events):
```java
// Add to pom.xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>

// Create KafkaProducerConfig.java
// Create UserEventPublisher.java
// Publish events on user registration, login, logout
```

**Step 3: Update Search Service** (Go - publish hotel events):
```go
// Add kafka-go dependency
go get github.com/segmentio/kafka-go

// Create kafka_producer.go
// Publish events on hotel CRUD operations
```

**Step 4: Update Notification Service** (consume all topics):
```python
# In app/main.py, update Kafka consumer
consumer = KafkaConsumer(
    'booking-events',
    'payment-events',
    'user-events',      # NEW
    'hotel-updates',    # NEW
    bootstrap_servers=['localhost:9092'],
    ...
)
```

---

### **Feature 4: RabbitMQ Dead Letter Exchange** (1.5 hours)

**Step 1: Configure DLX**:
```bash
# Create init-rabbitmq-dlx.sh
#!/bin/bash

# Declare Dead Letter Exchange
docker exec hotel-rabbitmq rabbitmqadmin declare exchange \
  name=payment_dlx type=direct durable=true

# Declare retry queue with DLX
docker exec hotel-rabbitmq rabbitmqadmin declare queue \
  name=payment.retry \
  durable=true \
  arguments='{"x-dead-letter-exchange":"payment_dlx","x-message-ttl":60000}'

# Declare dead letter queue
docker exec hotel-rabbitmq rabbitmqadmin declare queue \
  name=payment.dlq \
  durable=true

# Bind queues
docker exec hotel-rabbitmq rabbitmqadmin declare binding \
  source=payment_events destination=payment.retry routing_key=payment.retry

docker exec hotel-rabbitmq rabbitmqadmin declare binding \
  source=payment_dlx destination=payment.dlq routing_key=payment.failed
```

**Step 2: Update Payment Service**:
```go
// In internal/rabbitmq/publisher.go
// Publish to retry queue instead of failed queue
// Implement retry logic with exponential backoff
```

---

### **Feature 5: Analytics Service** (3 hours)

**Step 1: Create Analytics Service**:
```bash
mkdir -p services/analytics-service/app
cd services/analytics-service

# Create main.py
# Create Kafka consumer for all topics
# Create analytics database schema
# Implement reporting APIs
```

**Step 2: Create Analytics Database**:
```sql
-- init-db-analytics.sql
CREATE TABLE event_log (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50),
    event_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE booking_analytics (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER,
    hotel_id VARCHAR(50),
    total_price DECIMAL(10,2),
    created_at TIMESTAMP
);

CREATE TABLE payment_analytics (
    id SERIAL PRIMARY KEY,
    payment_id INTEGER,
    amount DECIMAL(10,2),
    status VARCHAR(20),
    created_at TIMESTAMP
);
```

**Step 3: Add to docker-compose**:
```yaml
postgres-analytics:
  image: postgres:16
  container_name: hotel-postgres-analytics
  environment:
    POSTGRES_USER: analytics_user
    POSTGRES_PASSWORD: analytics_pass
    POSTGRES_DB: analytics_db
  ports:
    - "5435:5432"
```

---

### **Feature 6: WebSocket for SSE** (2 hours)

**Step 1: Update Notification Service**:
```bash
cd services/notification-service
pip3 install python-socketio
```

```python
# In app/main.py
from socketio import AsyncServer
import socketio

sio = AsyncServer(async_mode='asgi', cors_allowed_origins='*')
app = socketio.ASGIApp(sio, app)

@sio.on('connect')
async def connect(sid, environ):
    print(f'Client connected: {sid}')

@sio.on('disconnect')
async def disconnect(sid):
    print(f'Client disconnected: {sid}')

# Emit notifications via WebSocket instead of SSE
await sio.emit('notification', notification_data, room=user_id)
```

**Step 2: Update Frontend**:
```bash
cd frontend
npm install socket.io-client
```

```typescript
// lib/notifications.ts
import { io } from 'socket.io-client';

const socket = io('http://localhost:8083');

socket.on('connect', () => {
  console.log('Connected to notification service');
});

socket.on('notification', (data) => {
  // Handle notification
  console.log('New notification:', data);
});
```

---

## 🐛 **Troubleshooting**

### **Problem: Services won't start**
```bash
# Check if ports are in use
lsof -ti:9000 | xargs kill -9  # Gateway
lsof -ti:8000 | xargs kill -9  # Booking
lsof -ti:8081 | xargs kill -9  # Search
lsof -ti:8082 | xargs kill -9  # Payment
lsof -ti:8083 | xargs kill -9  # Notification
```

### **Problem: Database connection failed**
```bash
# Check database status
docker ps | grep postgres

# Restart databases
docker-compose -f docker-compose-infrastructure.yml restart postgres-auth
docker-compose -f docker-compose-infrastructure.yml restart postgres-booking
docker-compose -f docker-compose-infrastructure.yml restart postgres-payment
```

### **Problem: Login fails**
```bash
# Reset all user passwords to admin123
docker exec hotel-postgres-auth psql -U auth_user -d auth_db \
  -c "UPDATE users SET password = '\$2b\$10\$rpUHEk7gb9rAUYjdUHemm.m8HEgalNTOOEen.wfb9hwH2ts.0REYu';"
```

### **Problem: Kafka not working**
```bash
# Check Kafka status
docker logs hotel-kafka

# Restart Kafka
docker-compose -f docker-compose-infrastructure.yml restart kafka zookeeper

# List topics
docker exec hotel-kafka kafka-topics --list --bootstrap-server localhost:9092
```

### **Problem: Redis cache not working**
```bash
# Check Redis
docker exec hotel-redis redis-cli ping
# Expected: PONG

# Clear cache
docker exec hotel-redis redis-cli FLUSHALL
```

---

## 📊 **Monitoring**

### **Check Infrastructure Health**:
```bash
docker-compose -f docker-compose-infrastructure.yml ps
```

### **Check Service Logs**:
```bash
# Gateway logs
cd gateway && npm start  # Check terminal output

# Booking service logs
cd services/booking-service && python3 -m app.main  # Check terminal output

# Kafka consumer groups
docker exec hotel-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --list

# RabbitMQ management UI
open http://localhost:15672
# Username: admin, Password: admin
```

---

## 🎯 **Next Steps**

1. ✅ **Verify all services are running** (use health check commands above)
2. ✅ **Test original functionality** (use workflow test above)
3. ✅ **Implement Kafka Extended Topics** (follow Feature 3 guide)
4. ✅ **Implement RabbitMQ DLX** (follow Feature 4 guide)
5. ✅ **Create Analytics Service** (follow Feature 5 guide)
6. ✅ **Replace SSE with WebSocket** (follow Feature 6 guide)
7. ✅ **(Optional) Add Service Mesh** (complex, 4-6 hours)

---

**System is ready! All original functionality is working perfectly.** 🚀

