# 🔐 OTP-Based Payment System - Complete Implementation

## ✅ What's Implemented

### **Real Services (No Mocks)**
1. ✅ **Booking Service** - Python/FastAPI + PostgreSQL + Kafka
2. ✅ **Payment Service** - Go + PostgreSQL + RabbitMQ + OTP Verification
3. ✅ **Notification Service** - Python/FastAPI + MongoDB + RabbitMQ

### **OTP Payment Flow**
1. User creates booking → Status: PENDING
2. System initiates payment → Generates 6-digit OTP
3. OTP displayed on screen (simulating SMS/Email)
4. User enters OTP to verify
5. If correct → Payment COMPLETED → Booking CONFIRMED
6. If incorrect → Payment FAILED → Retry or cancel

---

## 🏗️ Architecture & Technology Stack

### **Booking Service** (Port 8000)
- **Language**: Python 3.11
- **Framework**: FastAPI
- **Database**: PostgreSQL
- **Message Broker**: Kafka
- **Events Published**:
  - `BOOKING_CREATED` → When booking is created
  - `BOOKING_CONFIRMED` → When payment is verified
  - `BOOKING_CANCELLED` → When booking is cancelled

### **Payment Service** (Port 8082)
- **Language**: Go 1.21
- **Framework**: Gin
- **Database**: PostgreSQL
- **Message Broker**: RabbitMQ
- **Features**:
  - OTP generation (6-digit random code)
  - OTP verification
  - Transaction ID generation
  - Payment status tracking
- **Events Published**:
  - `payment.success` → When OTP is verified
  - `payment.failed` → When OTP is incorrect

### **Notification Service** (Port 8083)
- **Language**: Python 3.11
- **Framework**: FastAPI
- **Database**: MongoDB
- **Message Broker**: RabbitMQ (Consumer)
- **Features**:
  - Consumes events from RabbitMQ
  - Stores notifications in MongoDB
  - Supports EMAIL, SMS, PUSH channels

---

## 📊 Complete Booking & Payment Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       ├─→ 1. Select hotel, dates, rooms
       │
       ├─→ 2. Click "Reserve Now"
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  BOOKING SERVICE (Port 8000)                             │
│                                                          │
│  POST /booking/bookings                                  │
│  ├─→ Insert into PostgreSQL (status: PENDING)           │
│  ├─→ Publish BOOKING_CREATED event to Kafka             │
│  └─→ Return booking ID                                   │
└──────────────────────────────────────────────────────────┘
       │
       ├─→ 3. Initiate Payment
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  PAYMENT SERVICE (Port 8082)                             │
│                                                          │
│  POST /payment/initiate                                  │
│  ├─→ Generate 6-digit OTP (e.g., "123456")              │
│  ├─→ Insert into PostgreSQL (status: PENDING)           │
│  └─→ Return { paymentId, otp, status }                  │
└──────────────────────────────────────────────────────────┘
       │
       ├─→ 4. Display OTP on screen
       │      "Your OTP is: 123456"
       │
       ├─→ 5. User enters OTP
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  PAYMENT SERVICE (Port 8082)                             │
│                                                          │
│  POST /payment/verify-otp                                │
│  ├─→ Fetch payment from PostgreSQL                      │
│  ├─→ Compare entered OTP with stored OTP                │
│  │                                                       │
│  ├─→ IF MATCH:                                           │
│  │   ├─→ Generate transaction ID                        │
│  │   ├─→ Update status to COMPLETED                     │
│  │   ├─→ Publish payment.success to RabbitMQ            │
│  │   └─→ Return success                                 │
│  │                                                       │
│  └─→ IF NO MATCH:                                        │
│      ├─→ Publish payment.failed to RabbitMQ             │
│      └─→ Return error "Invalid OTP"                     │
└──────────────────────────────────────────────────────────┘
       │
       ├─→ 6. If payment successful, confirm booking
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  BOOKING SERVICE (Port 8000)                             │
│                                                          │
│  PUT /booking/bookings/:id/confirm                       │
│  ├─→ Update status to CONFIRMED                         │
│  ├─→ Store payment ID and transaction ID                │
│  ├─→ Publish BOOKING_CONFIRMED event to Kafka           │
│  └─→ Return confirmed booking                           │
└──────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  NOTIFICATION SERVICE (Port 8083)                        │
│                                                          │
│  RabbitMQ Consumer                                       │
│  ├─→ Consume payment.success event                      │
│  ├─→ Consume BOOKING_CONFIRMED event                    │
│  ├─→ Store notification in MongoDB                      │
│  └─→ Send EMAIL/SMS/PUSH (simulated)                    │
└──────────────────────────────────────────────────────────┘
```

---

## 🔌 API Endpoints

### **Booking Service** (via Gateway: `/booking/*`)

#### Create Booking
```http
POST /booking/bookings
Content-Type: application/json

{
  "userId": "2",
  "hotelId": "1",
  "hotelName": "Grand Plaza Hotel",
  "checkInDate": "2025-10-15",
  "checkOutDate": "2025-10-17",
  "rooms": 2,
  "adults": 4,
  "children": 1,
  "totalPrice": 1196.00
}

Response: 201 Created
{
  "id": "1",
  "userId": "2",
  "hotelId": "1",
  "hotelName": "Grand Plaza Hotel",
  "checkInDate": "2025-10-15",
  "checkOutDate": "2025-10-17",
  "rooms": 2,
  "adults": 4,
  "children": 1,
  "totalPrice": 1196.00,
  "status": "PENDING",
  "paymentStatus": "PENDING",
  "createdAt": "2025-10-12T10:30:00Z",
  "updatedAt": "2025-10-12T10:30:00Z"
}
```

#### Confirm Booking
```http
PUT /booking/bookings/1/confirm
Content-Type: application/json

{
  "paymentId": "1",
  "transactionId": "TXN-1728734567-1"
}

Response: 200 OK
{
  "id": "1",
  "status": "CONFIRMED",
  "paymentStatus": "COMPLETED",
  "paymentId": "1",
  "transactionId": "TXN-1728734567-1",
  ...
}
```

#### Cancel Booking
```http
PUT /booking/bookings/1/cancel

Response: 200 OK
{
  "id": "1",
  "status": "CANCELLED",
  ...
}
```

### **Payment Service** (via Gateway: `/payment/*`)

#### Initiate Payment (Generate OTP)
```http
POST /payment/initiate
Content-Type: application/json

{
  "bookingId": "1",
  "userId": "2",
  "amount": 1196.00
}

Response: 201 Created
{
  "paymentId": 1,
  "otp": "123456",  ← Display this to user
  "status": "PENDING",
  "message": "Please verify OTP to complete payment"
}
```

#### Verify OTP
```http
POST /payment/verify-otp
Content-Type: application/json

{
  "paymentId": "1",
  "otp": "123456"
}

Response (Success): 200 OK
{
  "id": 1,
  "bookingId": 1,
  "userId": 2,
  "amount": 1196.00,
  "status": "COMPLETED",
  "transactionId": "TXN-1728734567-1",
  "createdAt": "2025-10-12T10:30:00Z",
  "updatedAt": "2025-10-12T10:31:00Z"
}

Response (Failure): 400 Bad Request
{
  "error": "Invalid OTP"
}
```

#### Get Payment Status
```http
GET /payment/payments/1

Response: 200 OK
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

---

## 🗄️ Database Schemas

### **PostgreSQL - Bookings Table**
```sql
CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    hotel_id INTEGER NOT NULL,
    hotel_name VARCHAR(255) NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    rooms INTEGER NOT NULL DEFAULT 1,
    adults INTEGER NOT NULL DEFAULT 2,
    children INTEGER NOT NULL DEFAULT 0,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    payment_status VARCHAR(50) DEFAULT 'PENDING',
    payment_id INTEGER,
    transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### **PostgreSQL - Payments Table**
```sql
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    otp VARCHAR(6),
    transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### **MongoDB - Notifications Collection**
```javascript
{
  _id: ObjectId("..."),
  userId: "2",
  type: "PAYMENT_SUCCESS",
  title: "Payment Successful",
  message: "Your payment of $1196.00 has been processed successfully",
  channels: ["EMAIL", "SMS", "PUSH"],
  read: false,
  createdAt: ISODate("2025-10-12T10:31:00Z")
}
```

---

## 🚀 Running the Services

### **1. Start Infrastructure**
```bash
docker-compose -f docker-compose-infrastructure.yml up -d
```

### **2. Initialize Databases**
```bash
# PostgreSQL - Booking tables
docker exec -i hotel-postgres psql -U admin -d hotel_db < services/booking-service/init_db.sql

# PostgreSQL - Payment tables (auto-created by Go service)
# MongoDB - Notifications (auto-created by Python service)
```

### **3. Start Booking Service**
```bash
cd services/booking-service
pip install -r requirements.txt
python -m app.main
```

### **4. Start Payment Service**
```bash
cd services/payment-service
go run cmd/main.go
```

### **5. Start Notification Service**
```bash
cd services/notification-service
pip install -r requirements.txt
python -m app.main
```

### **6. Start API Gateway**
```bash
cd gateway
npm install
npm start
```

---

## ✅ Protocol Compliance Checklist

- [x] **PostgreSQL for Bookings**: Booking Service uses PostgreSQL
- [x] **PostgreSQL for Payments**: Payment Service uses PostgreSQL
- [x] **MongoDB for Notifications**: Notification Service uses MongoDB
- [x] **Kafka for Booking Events**: Booking Service publishes to Kafka
- [x] **RabbitMQ for Payment Events**: Payment Service publishes to RabbitMQ
- [x] **RabbitMQ for Notifications**: Notification Service consumes from RabbitMQ
- [x] **API Gateway Pattern**: All requests go through gateway
- [x] **OTP-Based Payment**: No third-party integration, OTP verification
- [x] **Event-Driven Architecture**: Services communicate via events
- [x] **Proper Status Flow**: PENDING → COMPLETED/FAILED

---

## 🧪 Testing the OTP Payment Flow

### **Test 1: Successful Payment**

1. **Create Booking**:
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
   **Response**: `{ "id": "1", "status": "PENDING", ... }`

2. **Initiate Payment**:
   ```bash
   curl -X POST http://localhost:9000/payment/initiate \
     -H "Content-Type: application/json" \
     -d '{
       "bookingId": "1",
       "userId": "2",
       "amount": 1196.00
     }'
   ```
   **Response**: `{ "paymentId": 1, "otp": "123456", ... }`
   **Note the OTP!**

3. **Verify OTP**:
   ```bash
   curl -X POST http://localhost:9000/payment/verify-otp \
     -H "Content-Type: application/json" \
     -d '{
       "paymentId": "1",
       "otp": "123456"
     }'
   ```
   **Response**: `{ "status": "COMPLETED", "transactionId": "TXN-...", ... }`

4. **Confirm Booking**:
   ```bash
   curl -X PUT http://localhost:9000/booking/bookings/1/confirm \
     -H "Content-Type: application/json" \
     -d '{
       "paymentId": "1",
       "transactionId": "TXN-1728734567-1"
     }'
   ```
   **Response**: `{ "status": "CONFIRMED", ... }`

### **Test 2: Failed Payment (Wrong OTP)**

1. Create booking (same as above)
2. Initiate payment (same as above, note OTP)
3. **Verify with wrong OTP**:
   ```bash
   curl -X POST http://localhost:9000/payment/verify-otp \
     -H "Content-Type: application/json" \
     -d '{
       "paymentId": "1",
       "otp": "999999"
     }'
   ```
   **Response**: `{ "error": "Invalid OTP" }`
4. User can retry with correct OTP

---

## 🎯 Summary

**Your hotel reservation system now has:**
- ✅ Real services (no mocks) using proper tech stack
- ✅ OTP-based payment verification (no third-party integration)
- ✅ PostgreSQL for bookings and payments
- ✅ MongoDB for notifications
- ✅ Kafka for booking events
- ✅ RabbitMQ for payment/notification events
- ✅ Proper protocol compliance
- ✅ Event-driven architecture
- ✅ Complete booking → payment → confirmation flow

**Just start the services and test the OTP payment flow!** 🚀

