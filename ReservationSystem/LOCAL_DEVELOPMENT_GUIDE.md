# Local Development Guide

## 🎯 Running Services Locally with Docker Infrastructure

This guide shows you how to run infrastructure (databases, message brokers) in Docker while running your application services locally for development.

---

## 📋 Step-by-Step Setup

### Step 1: Start Infrastructure Services

```bash
# Navigate to deploy directory
cd deploy

# Start all infrastructure services
docker-compose -f docker-compose-infra.yml up -d

# Verify all services are running
docker-compose -f docker-compose-infra.yml ps
```

You should see:
- ✅ hotel-postgres (PostgreSQL)
- ✅ hotel-mongo (MongoDB)
- ✅ hotel-redis (Redis)
- ✅ hotel-kafka (Kafka)
- ✅ hotel-zookeeper (Zookeeper)
- ✅ hotel-rabbitmq (RabbitMQ)

---

### Step 2: Configure Environment Variables

Copy `.env.example` to `.env` for each service:

```bash
# Auth Service
cp services/auth-service/.env.example services/auth-service/.env

# Search Service
cp services/search-service/.env.example services/search-service/.env

# Booking Service
cp services/booking-service/.env.example services/booking-service/.env

# Payment Service
cp services/payment-service/.env.example services/payment-service/.env

# Notification Service
cp services/notification-service/.env.example services/notification-service/.env

# Gateway
cp gateway/.env.example gateway/.env
```

---

### Step 3: Install Dependencies

#### Gateway (Node.js)
```bash
cd gateway
npm install
```

#### Booking Service (Python)
```bash
cd services/booking-service
pip install -r requirements.txt
# or use virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### Notification Service (Python)
```bash
cd services/notification-service
pip install -r requirements.txt
# or use virtual environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### Search Service (Go)
```bash
cd services/search-service
go mod download
go mod tidy
```

#### Payment Service (Go)
```bash
cd services/payment-service
go mod download
go mod tidy
```

#### Auth Service (Java)
```bash
cd services/auth-service
# Dependencies will be downloaded automatically by Maven
```

---

### Step 4: Run Services Locally

Open separate terminal windows for each service:

#### Terminal 1: Auth Service (Java/Spring Boot)
```bash
cd services/auth-service
mvn spring-boot:run
```
**Running on:** http://localhost:8080

#### Terminal 2: Search Service (Go)
```bash
cd services/search-service
go run cmd/main.go
```
**Running on:** http://localhost:8081

#### Terminal 3: Booking Service (Python/FastAPI)
```bash
cd services/booking-service
uvicorn app.main:app --reload --port 8000
```
**Running on:** http://localhost:8000

#### Terminal 4: Payment Service (Go)
```bash
cd services/payment-service
go run cmd/main.go
```
**Running on:** http://localhost:8082

#### Terminal 5: Notification Service (Python/FastAPI)
```bash
cd services/notification-service
uvicorn app.main:app --reload --port 8083
```
**Running on:** http://localhost:8083

#### Terminal 6: API Gateway (Node.js)
```bash
cd gateway
npm start
```
**Running on:** http://localhost:9000

---

## 🧪 Testing the Setup

### 1. Check Infrastructure Health

```bash
# PostgreSQL
docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT 1;"

# MongoDB
docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.version()"

# Redis
docker exec -it hotel-redis redis-cli ping

# RabbitMQ
curl -u admin:admin http://localhost:15672/api/overview

# Kafka
docker exec -it hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### 2. Check Service Health

```bash
# Auth Service
curl http://localhost:8080/actuator/health

# Search Service
curl http://localhost:8081/health

# Booking Service
curl http://localhost:8000/health

# Payment Service
curl http://localhost:8082/health

# Notification Service
curl http://localhost:8083/health

# API Gateway
curl http://localhost:9000/
```

### 3. Test API Endpoints

#### Register a User (Auth Service)
```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "phoneNumber": "+1234567890"
  }'
```

#### Login
```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

#### Search Hotels
```bash
curl "http://localhost:8081/search?location=NewYork&checkIn=2024-01-15&checkOut=2024-01-20&guests=2&rooms=1"
```

---

## 🔧 Service Configuration Details

### Auth Service (Port 8080)
- **Database**: PostgreSQL (localhost:5432)
- **Tables**: users
- **Endpoints**:
  - POST /auth/register
  - POST /auth/login
  - POST /auth/verify

### Search Service (Port 8081)
- **Database**: MongoDB (localhost:27017)
- **Cache**: Redis (localhost:6379)
- **Endpoints**:
  - GET /search
  - GET /hotels/:id
  - GET /hotels/:id/rooms

### Booking Service (Port 8000)
- **Database**: PostgreSQL (localhost:5432)
- **Cache**: Redis (localhost:6379)
- **Message Broker**: Kafka (localhost:9093)
- **Endpoints**:
  - GET /bookings
  - POST /bookings
  - GET /bookings/:id
  - PUT /bookings/:id
  - DELETE /bookings/:id

### Payment Service (Port 8082)
- **Database**: PostgreSQL (localhost:5432)
- **Message Broker**: RabbitMQ (localhost:5672)
- **Endpoints**:
  - POST /payments
  - GET /payments/:id
  - POST /payments/:id/refund

### Notification Service (Port 8083)
- **Message Broker**: RabbitMQ (localhost:5672)
- **Endpoints**:
  - GET /health

---

## 📊 Database Setup

### PostgreSQL - Create Tables

```bash
# Connect to PostgreSQL
docker exec -it hotel-postgres psql -U admin -d hotel_db
```

```sql
-- Users table (for Auth Service)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(50) DEFAULT 'CUSTOMER',
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bookings table (for Booking Service)
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    hotel_id INTEGER NOT NULL,
    room_id INTEGER NOT NULL,
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP NOT NULL,
    guests INTEGER NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'CONFIRMED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments table (for Payment Service)
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    status VARCHAR(50) DEFAULT 'PENDING',
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exit
\q
```

### MongoDB - Insert Sample Hotels

```bash
# Connect to MongoDB
docker exec -it hotel-mongo mongosh -u admin -p admin
```

```javascript
// Use hotel database
use hotel_db

// Insert sample hotels
db.hotels.insertMany([
  {
    name: "Grand Plaza Hotel",
    location: "New York",
    address: "123 Broadway, New York, NY 10001",
    rating: 4.5,
    description: "Luxury hotel in the heart of Manhattan",
    amenities: ["WiFi", "Pool", "Gym", "Restaurant", "Spa"],
    images: ["https://example.com/hotel1.jpg"],
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    name: "Seaside Resort",
    location: "Miami",
    address: "456 Ocean Drive, Miami, FL 33139",
    rating: 4.8,
    description: "Beautiful beachfront resort",
    amenities: ["WiFi", "Beach", "Pool", "Bar", "Water Sports"],
    images: ["https://example.com/hotel2.jpg"],
    created_at: new Date(),
    updated_at: new Date()
  }
])

// Verify
db.hotels.find().pretty()

// Exit
exit
```

### Kafka - Create Topics

```bash
# Create booking-events topic
docker exec -it hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic booking-events \
  --partitions 3 \
  --replication-factor 1

# Create payment-events topic
docker exec -it hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic payment-events \
  --partitions 3 \
  --replication-factor 1

# List topics
docker exec -it hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list
```

### RabbitMQ - Create Queues

```bash
# Create booking_notifications queue
docker exec -it hotel-rabbitmq rabbitmqadmin declare queue \
  name=booking_notifications \
  durable=true

# Create payment_notifications queue
docker exec -it hotel-rabbitmq rabbitmqadmin declare queue \
  name=payment_notifications \
  durable=true

# List queues
docker exec -it hotel-rabbitmq rabbitmqctl list_queues
```

---

## 🐛 Troubleshooting

### Service Can't Connect to Database

1. **Check if infrastructure is running:**
   ```bash
   docker-compose -f docker-compose-infra.yml ps
   ```

2. **Check connection strings in .env files**

3. **Test connection manually:**
   ```bash
   # PostgreSQL
   docker exec -it hotel-postgres psql -U admin -d hotel_db
   
   # MongoDB
   docker exec -it hotel-mongo mongosh -u admin -p admin
   ```

### Port Already in Use

```bash
# Find process using port
lsof -i :8080
lsof -i :8081
lsof -i :8000

# Kill process
kill -9 <PID>
```

### Maven Build Fails (Java Services)

```bash
# Clean and rebuild
mvn clean install

# Skip tests
mvn clean install -DskipTests
```

### Go Module Issues

```bash
# Clean module cache
go clean -modcache

# Re-download modules
go mod download
go mod tidy
```

### Python Dependencies Issues

```bash
# Upgrade pip
pip install --upgrade pip

# Install with verbose output
pip install -r requirements.txt -v
```

---

## 🔄 Development Workflow

1. **Start Infrastructure** (once per day)
   ```bash
   cd deploy && docker-compose -f docker-compose-infra.yml up -d
   ```

2. **Start Services** (in separate terminals)
   - Auth Service: `cd services/auth-service && mvn spring-boot:run`
   - Search Service: `cd services/search-service && go run cmd/main.go`
   - Booking Service: `cd services/booking-service && uvicorn app.main:app --reload --port 8000`
   - Payment Service: `cd services/payment-service && go run cmd/main.go`
   - Notification Service: `cd services/notification-service && uvicorn app.main:app --reload --port 8083`
   - Gateway: `cd gateway && npm start`

3. **Make Changes** - Edit code, services will auto-reload

4. **Test** - Use curl or Postman to test endpoints

5. **Stop Services** - Ctrl+C in each terminal

6. **Stop Infrastructure** (end of day)
   ```bash
   cd deploy && docker-compose -f docker-compose-infra.yml down
   ```

---

## ✅ Quick Verification Checklist

- [ ] Infrastructure running: `docker-compose -f docker-compose-infra.yml ps`
- [ ] PostgreSQL accessible: `docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT 1;"`
- [ ] MongoDB accessible: `docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.version()"`
- [ ] Redis accessible: `docker exec -it hotel-redis redis-cli ping`
- [ ] RabbitMQ UI accessible: http://localhost:15672
- [ ] Kafka topics created: `docker exec -it hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list`
- [ ] Auth Service running: `curl http://localhost:8080/actuator/health`
- [ ] Search Service running: `curl http://localhost:8081/health`
- [ ] Booking Service running: `curl http://localhost:8000/health`
- [ ] Payment Service running: `curl http://localhost:8082/health`
- [ ] Notification Service running: `curl http://localhost:8083/health`
- [ ] Gateway running: `curl http://localhost:9000/`

All checks passed? You're ready to develop! 🚀

