# 🚀 Running Services Manually - Complete Guide

## ✅ Step 1: Start Infrastructure (Docker Only)

```bash
# Start all infrastructure services
./start-infrastructure-only.sh
```

This will start:
- ✅ PostgreSQL (localhost:5432)
- ✅ MongoDB (localhost:27017)
- ✅ Redis (localhost:6379)
- ✅ Kafka (localhost:9093)
- ✅ RabbitMQ (localhost:5672)

---

## 📋 Step 2: Copy Environment Files

```bash
# Copy .env.example to .env for each service
cp services/auth-service/.env.example services/auth-service/.env
cp services/search-service/.env.example services/search-service/.env
cp services/booking-service/.env.example services/booking-service/.env
cp services/payment-service/.env.example services/payment-service/.env
cp services/notification-service/.env.example services/notification-service/.env
cp gateway/.env.example gateway/.env
```

---

## 🎯 Step 3: Run Services Manually

Open **6 separate terminal windows** and run each service:

### Terminal 1: Auth Service (Java/Spring Boot)

```bash
cd services/auth-service

# Option 1: Using Maven
mvn spring-boot:run

# Option 2: Using Gradle (if you have build.gradle)
./gradlew bootRun

# Option 3: Build and run JAR
mvn clean package
java -jar target/auth-service-0.0.1-SNAPSHOT.jar
```

**Running on:** http://localhost:8080

**Test:**
```bash
curl http://localhost:8080/actuator/health
```

---

### Terminal 2: Search Service (Go)

```bash
cd services/search-service

# Install dependencies (first time only)
go mod download
go mod tidy

# Run the service
go run cmd/main.go
```

**Running on:** http://localhost:8081

**Test:**
```bash
curl http://localhost:8081/health
```

---

### Terminal 3: Booking Service (Python/FastAPI)

```bash
cd services/booking-service

# Create virtual environment (first time only)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the service
uvicorn app.main:app --reload --port 8000 --host 0.0.0.0
```

**Running on:** http://localhost:8000

**Test:**
```bash
curl http://localhost:8000/health
curl http://localhost:8000/docs  # Swagger UI
```

---

### Terminal 4: Payment Service (Go)

```bash
cd services/payment-service

# Install dependencies (first time only)
go mod download
go mod tidy

# Run the service
go run cmd/main.go
```

**Running on:** http://localhost:8082

**Test:**
```bash
curl http://localhost:8082/health
```

---

### Terminal 5: Notification Service (Python/FastAPI)

```bash
cd services/notification-service

# Create virtual environment (first time only)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the service
uvicorn app.main:app --reload --port 8083 --host 0.0.0.0
```

**Running on:** http://localhost:8083

**Test:**
```bash
curl http://localhost:8083/health
```

---

### Terminal 6: API Gateway (Node.js)

```bash
cd gateway

# Install dependencies (first time only)
npm install

# Run the service
npm start
```

**Running on:** http://localhost:9000

**Test:**
```bash
curl http://localhost:9000/
```

---

## 🧪 Step 4: Test the Complete System

### 1. Register a User (Auth Service)

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@hotel.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@hotel.com",
    "password": "password123"
  }'
```

**Save the JWT token from the response!**

### 3. Search Hotels (Search Service)

```bash
# Search by location
curl "http://localhost:8081/search?location=New%20York"

# Search with filters
curl "http://localhost:8081/search?location=Miami&minPrice=100&maxPrice=500&minRating=4"

# Get specific hotel
curl "http://localhost:8081/hotels/hotel_001"
```

### 4. Create Booking (Booking Service)

```bash
curl -X POST http://localhost:8000/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "hotelId": "hotel_001",
    "roomId": "room_101",
    "checkIn": "2024-02-01",
    "checkOut": "2024-02-05",
    "guests": 2,
    "totalPrice": 1000.00
  }'
```

### 5. Process Payment (Payment Service)

```bash
curl -X POST http://localhost:8082/payments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "bookingId": 1,
    "amount": 1000.00,
    "paymentMethod": "credit_card",
    "cardNumber": "4111111111111111",
    "cardExpiry": "12/25",
    "cardCvv": "123"
  }'
```

### 6. Test via Gateway

```bash
# All requests can go through the gateway
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "gateway@hotel.com",
    "password": "password123",
    "firstName": "Gateway",
    "lastName": "User"
  }'

curl "http://localhost:9000/search?location=Miami"
```

---

## 🗄️ Access Databases

### PostgreSQL

```bash
# Connect to PostgreSQL
docker exec -it hotel-postgres psql -U admin -d hotel_db

# View users
SELECT * FROM users;

# View bookings
SELECT * FROM bookings;

# View payments
SELECT * FROM payments;

# Exit
\q
```

### MongoDB

```bash
# Connect to MongoDB
docker exec -it hotel-mongo mongosh -u admin -p admin

# Use hotel database
use hotel_db

# View hotels
db.hotels.find().pretty()

# Search hotels by location
db.hotels.find({ location: "New York" }).pretty()

# Exit
exit
```

### Redis

```bash
# Connect to Redis
docker exec -it hotel-redis redis-cli

# View all keys
KEYS *

# Get a value
GET some_key

# Exit
exit
```

### RabbitMQ Management UI

Open browser: **http://localhost:15672**
- Username: `admin`
- Password: `admin`

View queues:
- `booking_notifications`
- `payment_notifications`

### Kafka

```bash
# List topics
docker exec -it hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list

# Consume booking events
docker exec -it hotel-kafka kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic booking-events \
  --from-beginning

# Consume payment events
docker exec -it hotel-kafka kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic payment-events \
  --from-beginning
```

---

## 📊 Connection Details Summary

| Service | Host | Port | Credentials |
|---------|------|------|-------------|
| PostgreSQL | localhost | 5432 | admin / admin |
| MongoDB | localhost | 27017 | admin / admin |
| Redis | localhost | 6379 | - |
| Kafka | localhost | 9093 | - |
| RabbitMQ | localhost | 5672 | admin / admin |
| RabbitMQ UI | localhost | 15672 | admin / admin |

---

## 🔍 Troubleshooting

### Service Can't Connect to Database

1. **Check if infrastructure is running:**
   ```bash
   docker ps
   ```

2. **Check logs:**
   ```bash
   docker-compose -f docker-compose-infrastructure.yml logs -f postgres
   docker-compose -f docker-compose-infrastructure.yml logs -f mongo
   ```

3. **Test connection manually:**
   ```bash
   docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT 1;"
   docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.version()"
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

### Java Service Won't Start

```bash
# Clean and rebuild
cd services/auth-service
mvn clean install

# Check Java version
java -version  # Should be Java 17 or higher
```

### Go Service Won't Start

```bash
# Clean module cache
go clean -modcache

# Re-download modules
go mod download
go mod tidy
```

### Python Service Won't Start

```bash
# Upgrade pip
pip install --upgrade pip

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

---

## 🛑 Stop Everything

### Stop Services
Press `Ctrl+C` in each terminal window

### Stop Infrastructure

```bash
docker-compose -f docker-compose-infrastructure.yml down
```

### Stop and Remove Data

```bash
docker-compose -f docker-compose-infrastructure.yml down -v
```

---

## 📝 Development Workflow

### Daily Workflow

1. **Morning:**
   ```bash
   ./start-infrastructure-only.sh
   ```

2. **Start services** in separate terminals (as shown above)

3. **Develop** - Make changes, services will auto-reload

4. **Test** - Use curl or Postman

5. **Evening:**
   ```bash
   docker-compose -f docker-compose-infrastructure.yml down
   ```

---

## ✅ Quick Verification Checklist

- [ ] Infrastructure running: `docker ps`
- [ ] PostgreSQL accessible: `docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT 1;"`
- [ ] MongoDB accessible: `docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.version()"`
- [ ] Redis accessible: `docker exec -it hotel-redis redis-cli ping`
- [ ] RabbitMQ UI accessible: http://localhost:15672
- [ ] Kafka topics exist: `docker exec -it hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list`
- [ ] Auth Service: `curl http://localhost:8080/actuator/health`
- [ ] Search Service: `curl http://localhost:8081/health`
- [ ] Booking Service: `curl http://localhost:8000/health`
- [ ] Payment Service: `curl http://localhost:8082/health`
- [ ] Notification Service: `curl http://localhost:8083/health`
- [ ] Gateway: `curl http://localhost:9000/`

---

**Happy Coding! 🚀**

