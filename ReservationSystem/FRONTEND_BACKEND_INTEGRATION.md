# 🔗 Frontend-Backend Integration Guide

## ✅ Integration Complete!

Your frontend is now fully integrated with the backend services following your architecture and protocol flow diagrams.

---

## 🎯 What Was Integrated

### 1. **API Gateway Updates** ✅
- Added CORS support for frontend communication
- Environment variable support for local development
- Proper routing to all microservices
- Health check endpoint

### 2. **Frontend API Client Updates** ✅
- Updated all endpoints to match gateway routes
- Proper JWT token handling
- Request/response interceptors
- Error handling with auto-redirect on 401

### 3. **Authentication Flow** ✅
Following your architecture diagram:
```
Frontend → API Gateway → Auth Service → PostgreSQL → JWT Token → Frontend
```

### 4. **Service Endpoints** ✅
All endpoints now correctly route through the API Gateway:

| Service | Gateway Route | Backend Service | Port |
|---------|---------------|-----------------|------|
| Auth | `/auth/*` | Auth Service | 8080 |
| Search | `/search/*` | Search Service | 8081 |
| Booking | `/booking/*` | Booking Service | 8000 |
| Payment | `/payment/*` | Payment Service | 8082 |
| Notification | `/notify/*` | Notification Service | 8083 |

---

## 🚀 How to Run the Complete System

### Step 1: Start Infrastructure (Docker)

```bash
# Start PostgreSQL, MongoDB, Redis, Kafka, RabbitMQ
docker-compose -f docker-compose-infrastructure.yml up -d

# Verify all containers are running
docker-compose -f docker-compose-infrastructure.yml ps
```

### Step 2: Start Backend Services

**Option A: Use the automated script**
```bash
./start-backend-local.sh
```

**Option B: Start services manually**

```bash
# 1. API Gateway (Terminal 1)
cd gateway
npm install
npm start

# 2. Auth Service (Terminal 2)
cd services/auth-service
./mvnw spring-boot:run

# 3. Search Service (Terminal 3)
cd services/search-service
go run cmd/main.go

# 4. Booking Service (Terminal 4)
cd services/booking-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# 5. Payment Service (Terminal 5)
cd services/payment-service
go run cmd/main.go

# 6. Notification Service (Terminal 6)
cd services/notification-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --port 8083 --reload
```

### Step 3: Start Frontend

```bash
cd frontend
npm run dev
```

### Step 4: Test the Integration

```bash
# Run automated integration tests
./test-integration.sh
```

---

## 🔄 Complete User Flow (Following Your Architecture)

### 1. **User Registration Flow**

```
User (Browser)
    │
    ├─→ Fill registration form
    │
    ├─→ POST /auth/register (Frontend)
    │   {
    │     email, password, firstName, lastName, phoneNumber
    │   }
    │
    ├─→ POST http://localhost:9000/auth/register (API Gateway)
    │
    ├─→ POST http://localhost:8080/auth/register (Auth Service)
    │
    ├─→ INSERT INTO users (PostgreSQL)
    │   - Hash password with BCrypt
    │   - Set role = CUSTOMER
    │   - Set enabled = true
    │
    ├─→ Generate JWT Token (JwtService)
    │   - Claims: userId, email, role
    │   - Expiration: 24 hours
    │
    ├─→ 201 Created Response
    │   {
    │     token: "eyJhbGc...",
    │     user: { id, email, firstName, lastName, role }
    │   }
    │
    ├─→ Store in Zustand + localStorage (Frontend)
    │
    └─→ Redirect to /login
```

### 2. **User Login Flow**

```
User (Browser)
    │
    ├─→ Enter email & password
    │
    ├─→ POST /auth/login (Frontend)
    │   { email, password }
    │
    ├─→ POST http://localhost:9000/auth/login (API Gateway)
    │
    ├─→ POST http://localhost:8080/auth/login (Auth Service)
    │
    ├─→ SELECT * FROM users WHERE email = ? (PostgreSQL)
    │
    ├─→ Verify password with BCrypt
    │
    ├─→ Generate JWT Token
    │
    ├─→ 200 OK Response
    │   {
    │     token: "eyJhbGc...",
    │     user: { id, email, firstName, lastName, role }
    │   }
    │
    ├─→ Store in Zustand + localStorage
    │
    └─→ Redirect to /dashboard (CUSTOMER) or /admin (ADMIN)
```

### 3. **Hotel Search Flow**

```
User (Browser)
    │
    ├─→ Enter search criteria (city, dates, guests)
    │
    ├─→ GET /search/hotels?city=NYC&checkIn=...&checkOut=... (Frontend)
    │   Headers: { Authorization: "Bearer <token>" }
    │
    ├─→ GET http://localhost:9000/search/hotels?... (API Gateway)
    │
    ├─→ GET http://localhost:8081/search/hotels?... (Search Service)
    │
    ├─→ Check Redis cache first
    │   - Cache key: "hotels:NYC:2024-12-01:2024-12-05"
    │   - TTL: 5 minutes
    │
    ├─→ If cache miss: Query MongoDB
    │   db.hotels.find({
    │     city: "NYC",
    │     available_rooms: { $gte: guests }
    │   })
    │
    ├─→ Store result in Redis
    │
    ├─→ 200 OK Response
    │   [
    │     { _id, name, city, price_per_night, rating, ... }
    │   ]
    │
    └─→ Display HotelCard components
```

### 4. **Booking Creation Flow**

```
User (Browser)
    │
    ├─→ Click "Book Now" on hotel
    │
    ├─→ POST /booking/bookings (Frontend)
    │   {
    │     hotelId, checkInDate, checkOutDate,
    │     numberOfGuests, totalPrice
    │   }
    │   Headers: { Authorization: "Bearer <token>" }
    │
    ├─→ POST http://localhost:9000/booking/bookings (API Gateway)
    │
    ├─→ POST http://localhost:8000/bookings (Booking Service)
    │
    ├─→ Extract userId from JWT token
    │
    ├─→ INSERT INTO bookings (PostgreSQL)
    │   - status = PENDING
    │   - created_at = NOW()
    │
    ├─→ Publish event to Kafka
    │   Topic: "booking-events"
    │   Event: {
    │     type: "BOOKING_CREATED",
    │     bookingId, userId, hotelId, totalPrice
    │   }
    │
    ├─→ Payment Service consumes event
    │   - Process payment
    │   - Update booking status
    │   - Publish to RabbitMQ
    │
    ├─→ Notification Service consumes from RabbitMQ
    │   - Send confirmation email
    │   - Send SMS notification
    │
    ├─→ 201 Created Response
    │   {
    │     id, userId, hotelId, status, totalPrice, ...
    │   }
    │
    └─→ Redirect to /reservations
```

---

## 🔐 Authentication & Authorization

### JWT Token Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "userId": 1,
    "email": "user@hotel.com",
    "role": "CUSTOMER",
    "sub": "user@hotel.com",
    "iat": 1234567890,
    "exp": 1234654290
  },
  "signature": "..."
}
```

### Token Flow

1. **Frontend** stores token in:
   - Zustand store (in-memory)
   - localStorage (persistence)

2. **Every API request** includes:
   ```
   Authorization: Bearer <token>
   ```

3. **Backend services** verify token:
   - Extract from Authorization header
   - Validate signature with JWT secret
   - Check expiration
   - Extract user info from claims

4. **On 401 Unauthorized**:
   - Frontend clears auth state
   - Redirects to /login

---

## 📡 API Endpoints Reference

### Auth Service (via `/auth`)

```bash
# Register
POST /auth/register
Body: { email, password, firstName, lastName, phoneNumber }
Response: { token, user }

# Login
POST /auth/login
Body: { email, password }
Response: { token, user }

# Verify Token
POST /auth/verify
Headers: { Authorization: "Bearer <token>" }
Response: { user }

# Get Profile
GET /auth/profile
Headers: { Authorization: "Bearer <token>" }
Response: { user }

# Update Profile
PUT /auth/profile
Headers: { Authorization: "Bearer <token>" }
Body: { firstName, lastName, phoneNumber }
Response: { user }
```

### Search Service (via `/search`)

```bash
# Search Hotels
GET /search/hotels?city=NYC&checkIn=2024-12-01&checkOut=2024-12-05&guests=2
Headers: { Authorization: "Bearer <token>" }
Response: [ { hotel objects } ]

# Get Hotel by ID
GET /search/hotels/:id
Headers: { Authorization: "Bearer <token>" }
Response: { hotel object }
```

### Booking Service (via `/booking`)

```bash
# Create Booking
POST /booking/bookings
Headers: { Authorization: "Bearer <token>" }
Body: { hotelId, checkInDate, checkOutDate, numberOfGuests, totalPrice }
Response: { booking object }

# Get All Bookings
GET /booking/bookings
Headers: { Authorization: "Bearer <token>" }
Response: [ { booking objects } ]

# Get Booking by ID
GET /booking/bookings/:id
Headers: { Authorization: "Bearer <token>" }
Response: { booking object }

# Cancel Booking
PUT /booking/bookings/:id/cancel
Headers: { Authorization: "Bearer <token>" }
Response: { booking object }
```

### Payment Service (via `/payment`)

```bash
# Process Payment
POST /payment/payments
Headers: { Authorization: "Bearer <token>" }
Body: { bookingId, amount, paymentMethod }
Response: { payment object }

# Get Payment by ID
GET /payment/payments/:id
Headers: { Authorization: "Bearer <token>" }
Response: { payment object }
```

### Notification Service (via `/notify`)

```bash
# Get All Notifications
GET /notify/notifications
Headers: { Authorization: "Bearer <token>" }
Response: [ { notification objects } ]

# Mark as Read
PUT /notify/notifications/:id/read
Headers: { Authorization: "Bearer <token>" }
Response: { notification object }

# Mark All as Read
PUT /notify/notifications/read-all
Headers: { Authorization: "Bearer <token>" }
Response: { success: true }
```

---

## 🧪 Testing the Integration

### Manual Testing

1. **Open Frontend**: http://localhost:3000
2. **Register a new account**
3. **Login with credentials**
4. **Search for hotels**
5. **Create a booking**
6. **View reservations**

### Automated Testing

```bash
# Run integration test script
./test-integration.sh

# This will test:
# - User registration
# - User login
# - Token verification
# - Hotel search
# - Booking creation
# - Payment processing
```

### Using cURL

```bash
# 1. Register
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@hotel.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "phoneNumber": "+1234567890"
  }'

# 2. Login (save the token)
TOKEN=$(curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@hotel.com",
    "password": "password123"
  }' | jq -r '.token')

# 3. Search Hotels
curl -X GET "http://localhost:9000/search/hotels?city=New%20York" \
  -H "Authorization: Bearer $TOKEN"

# 4. Create Booking
curl -X POST http://localhost:9000/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "hotelId": "hotel-123",
    "checkInDate": "2024-12-01",
    "checkOutDate": "2024-12-05",
    "numberOfGuests": 2,
    "totalPrice": 500.00
  }'
```

---

## 🐛 Troubleshooting

### Frontend can't connect to backend

**Check:**
1. API Gateway is running on port 9000
2. CORS is enabled in gateway
3. Frontend .env.local has correct API_URL

```bash
# Check gateway
curl http://localhost:9000/health

# Check CORS
curl -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS http://localhost:9000/auth/login -v
```

### Login/Register not working

**Check:**
1. Auth Service is running on port 8080
2. PostgreSQL is running and accessible
3. Database has users table

```bash
# Check auth service
curl http://localhost:8080/actuator/health

# Check database
docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT * FROM users;"
```

### Token errors (401 Unauthorized)

**Check:**
1. Token is being sent in Authorization header
2. JWT secret matches between services
3. Token hasn't expired (24 hours)

```bash
# Verify token
curl -X POST http://localhost:9000/auth/verify \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Services not starting

**Check logs:**
```bash
# View all logs
tail -f logs/*.log

# View specific service
tail -f logs/auth-service.log
```

---

## 📊 System Status Check

```bash
# Check all services
echo "API Gateway:"; curl -s http://localhost:9000/health | jq
echo "Auth Service:"; curl -s http://localhost:8080/actuator/health | jq
echo "Search Service:"; curl -s http://localhost:8081/health | jq
echo "Booking Service:"; curl -s http://localhost:8000/health | jq
echo "Payment Service:"; curl -s http://localhost:8082/health | jq
echo "Notification Service:"; curl -s http://localhost:8083/health | jq
```

---

## 🎉 Summary

✅ **Frontend** integrated with **Backend**  
✅ **API Gateway** routing all requests  
✅ **Authentication** flow working  
✅ **JWT tokens** properly handled  
✅ **All services** connected  
✅ **Following your architecture** and protocol diagrams  

**You can now:**
- Register and login users
- Search for hotels
- Create bookings
- Process payments
- View notifications

**Everything is working according to your flow diagrams!** 🚀

