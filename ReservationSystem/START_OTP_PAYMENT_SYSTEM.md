# 🚀 Start OTP Payment System - Quick Guide

## ✅ Prerequisites

Make sure infrastructure is running:
```bash
docker-compose -f docker-compose-infrastructure.yml ps
```

All services should be "Up" and "healthy":
- hotel-postgres (Port 5432)
- hotel-mongo (Port 27017)
- hotel-redis (Port 6379)
- hotel-kafka (Port 9092/9093)
- hotel-zookeeper (Port 2181)
- hotel-rabbitmq (Port 5672/15672)

---

## 🗄️ Step 1: Initialize Databases

### PostgreSQL (Bookings & Payments)
```bash
docker exec -i hotel-postgres psql -U admin -d hotel_db < init-booking-payment-db.sql
```

**Expected Output:**
```
CREATE TABLE
CREATE TABLE
CREATE INDEX
...
Bookings table created/verified
Payments table created/verified
```

### Verify Tables
```bash
docker exec hotel-postgres psql -U admin -d hotel_db -c "\dt"
```

You should see:
- `bookings`
- `payments`
- `users` (from auth service)

---

## 🚀 Step 2: Start Backend Services

### Terminal 1: Booking Service (Python/FastAPI)
```bash
cd services/booking-service
pip install -r requirements.txt
python -m app.main
```

**Expected Output:**
```
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Terminal 2: Payment Service (Go)
```bash
cd services/payment-service
go run cmd/main.go
```

**Expected Output:**
```
💳 Payment Service starting on port 8082
📡 Health check: http://localhost:8082/health
💰 Initiate payment: POST http://localhost:8082/payment/initiate
🔐 Verify OTP: POST http://localhost:8082/payment/verify-otp
```

### Terminal 3: Notification Service (Python/FastAPI)
```bash
cd services/notification-service
pip install -r requirements.txt
python -m app.main
```

**Expected Output:**
```
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8083
🐰 Listening for events from RabbitMQ...
```

### Terminal 4: API Gateway (Node.js)
```bash
cd gateway
npm install
npm start
```

**Expected Output:**
```
🚀 API Gateway running on port 9000
📡 Services:
   - Auth: http://localhost:8080
   - Search: http://localhost:8081
   - Booking: http://localhost:8000
   - Payment: http://localhost:8082
   - Notification: http://localhost:8083
```

### Terminal 5: Auth Service (Already running)
Should already be running from previous setup on port 8080.

### Terminal 6: Search Service (Already running)
Should already be running from previous setup on port 8081.

---

## 🌐 Step 3: Start Frontend

### Terminal 7: Frontend (Next.js)
```bash
cd frontend
npm run dev
```

**Expected Output:**
```
  ▲ Next.js 14.x.x
  - Local:        http://localhost:3000
  - Ready in X.Xs
```

---

## 🧪 Step 4: Test the OTP Payment Flow

### Option 1: Via Browser (Recommended)

1. **Open Browser:**
   ```
   http://localhost:3000
   ```

2. **Login:**
   - Email: `test@hotel.com`
   - Password: `password123`

3. **Search for Hotels:**
   - Go to Dashboard or Search page
   - Browse available hotels

4. **Select a Hotel:**
   - Click on any hotel card
   - View hotel details

5. **Make a Reservation:**
   - Select check-in and check-out dates
   - Choose rooms, adults, children
   - Click "Reserve Now"

6. **Booking Confirmation Page:**
   - Review booking summary
   - Click "Confirm & Generate OTP"
   - Wait for OTP to be generated

7. **OTP Verification:**
   - You'll see a 6-digit OTP displayed on screen (e.g., "123456")
   - Enter the same OTP in the input field
   - Click "Verify OTP & Complete Payment"

8. **Success:**
   - Payment will be verified
   - Booking will be confirmed
   - You'll be redirected to "My Reservations"

### Option 2: Via API (cURL)

#### Step 1: Create Booking
```bash
curl -X POST http://localhost:9000/booking/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "2",
    "hotelId": "1",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-10-15",
    "checkOutDate": "2025-10-17",
    "rooms": 2,
    "adults": 4,
    "children": 1,
    "totalPrice": 1196.00
  }'
```

**Response:**
```json
{
  "id": "1",
  "userId": "2",
  "hotelId": "1",
  "status": "PENDING",
  "paymentStatus": "PENDING",
  ...
}
```

#### Step 2: Initiate Payment (Get OTP)
```bash
curl -X POST http://localhost:9000/payment/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "1",
    "userId": "2",
    "amount": 1196.00
  }'
```

**Response:**
```json
{
  "paymentId": 1,
  "otp": "123456",  ← Note this OTP!
  "status": "PENDING",
  "message": "Please verify OTP to complete payment"
}
```

#### Step 3: Verify OTP
```bash
curl -X POST http://localhost:9000/payment/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "paymentId": "1",
    "otp": "123456"
  }'
```

**Response (Success):**
```json
{
  "id": 1,
  "bookingId": 1,
  "userId": 2,
  "amount": 1196.00,
  "status": "COMPLETED",
  "transactionId": "TXN-1728734567-1",
  ...
}
```

**Response (Failure - Wrong OTP):**
```json
{
  "error": "Invalid OTP"
}
```

#### Step 4: Confirm Booking
```bash
curl -X PUT http://localhost:9000/booking/bookings/1/confirm \
  -H "Content-Type: application/json" \
  -d '{
    "paymentId": "1",
    "transactionId": "TXN-1728734567-1"
  }'
```

**Response:**
```json
{
  "id": "1",
  "status": "CONFIRMED",
  "paymentStatus": "COMPLETED",
  "paymentId": "1",
  "transactionId": "TXN-1728734567-1",
  ...
}
```

---

## 📊 Step 5: Monitor Events

### Watch Booking Service Logs (Terminal 1)
You should see:
```
📨 Published BOOKING_CREATED event to Kafka for booking 1
📨 Published BOOKING_CONFIRMED event to Kafka for booking 1
```

### Watch Payment Service Logs (Terminal 2)
You should see:
```
💳 Payment initiated: ID=1, OTP=123456
✅ Payment completed: ID=1, TXN=TXN-1728734567-1
📨 Published payment.success event to RabbitMQ
```

### Watch Notification Service Logs (Terminal 3)
You should see:
```
📧 [EMAIL] To: user-2@hotel.com
   Subject: Payment Successful
📱 [SMS] To: +1-XXX-XXX-0002
   Message: Your payment of $1196.00 has been processed
🔔 [PUSH] To: device-2
   Title: Booking Confirmed!
```

---

## 🔍 Step 6: Verify Data

### Check Bookings in PostgreSQL
```bash
docker exec hotel-postgres psql -U admin -d hotel_db -c "SELECT id, user_id, hotel_name, status, payment_status FROM bookings;"
```

### Check Payments in PostgreSQL
```bash
docker exec hotel-postgres psql -U admin -d hotel_db -c "SELECT id, booking_id, amount, status, transaction_id FROM payments;"
```

### Check Notifications in MongoDB
```bash
docker exec hotel-mongo mongosh -u admin -p admin --authenticationDatabase admin hotel_db --eval "db.notifications.find().pretty()"
```

---

## ❌ Troubleshooting

### Issue: "Failed to connect to database"
**Solution:**
```bash
# Check if PostgreSQL is running
docker ps | grep hotel-postgres

# Restart if needed
docker restart hotel-postgres
```

### Issue: "Failed to connect to RabbitMQ"
**Solution:**
```bash
# Check if RabbitMQ is running
docker ps | grep hotel-rabbitmq

# Restart if needed
docker restart hotel-rabbitmq
```

### Issue: "Failed to publish to Kafka"
**Solution:**
```bash
# Check if Kafka is running
docker ps | grep hotel-kafka

# Restart Kafka and Zookeeper
docker restart hotel-zookeeper hotel-kafka
```

### Issue: Port already in use
**Solution:**
```bash
# Find process using the port (e.g., 8000)
lsof -i :8000

# Kill the process
kill -9 <PID>
```

---

## 🎯 Quick Health Checks

```bash
# API Gateway
curl http://localhost:9000/health

# Booking Service
curl http://localhost:8000/health

# Payment Service
curl http://localhost:8082/health

# Notification Service
curl http://localhost:8083/health

# Auth Service
curl http://localhost:8080/actuator/health

# Search Service
curl http://localhost:8081/health
```

All should return `{"status": "healthy"}` or similar.

---

## 📝 Summary

**Services Running:**
1. ✅ Booking Service (Port 8000) - Python/FastAPI + PostgreSQL + Kafka
2. ✅ Payment Service (Port 8082) - Go + PostgreSQL + RabbitMQ
3. ✅ Notification Service (Port 8083) - Python/FastAPI + MongoDB + RabbitMQ
4. ✅ API Gateway (Port 9000) - Node.js
5. ✅ Auth Service (Port 8080) - Mock/Node.js
6. ✅ Search Service (Port 8081) - Mock/Node.js
7. ✅ Frontend (Port 3000) - Next.js

**Infrastructure:**
- PostgreSQL (Port 5432)
- MongoDB (Port 27017)
- Redis (Port 6379)
- Kafka (Port 9092/9093)
- Zookeeper (Port 2181)
- RabbitMQ (Port 5672/15672)

**OTP Payment Flow:**
1. Create Booking → PENDING
2. Initiate Payment → Get OTP
3. Verify OTP → Payment COMPLETED
4. Confirm Booking → CONFIRMED

**Just follow the steps and test the complete OTP payment flow!** 🎉

