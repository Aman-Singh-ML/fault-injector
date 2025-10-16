# Backend Services Startup Guide

## Current Status

✅ **API Gateway** - Running on port 9000 with CORS enabled  
❌ **Auth Service** - Compilation issues with Lombok  
⏸️ **Other Services** - Not started yet

---

## Issue: Auth Service Lombok Compilation Error

The Auth Service is experiencing Lombok annotation processing issues with Java 21 and Maven.

### Error:
```
Fatal error compiling: java.lang.ExceptionInInitializerError: com.sun.tools.javac.code.TypeTag :: UNKNOWN
```

### Root Cause:
- System is using Java 21
- Lombok version compatibility issue with Maven compiler plugin
- Annotation processor not being invoked correctly

---

## Solution Options

### Option 1: Use Docker (Recommended)

The easiest way to run all backend services is using Docker Compose:

```bash
# Start all backend services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f auth-service
```

**Advantages:**
- No local Java/Maven setup needed
- All services run in isolated containers
- Consistent environment
- Easy to start/stop all services

### Option 2: Fix Lombok and Run Locally

If you want to run services locally, here's how to fix the Lombok issue:

#### Step 1: Install Java 17 (Recommended for Spring Boot 3.2.0)

```bash
# Using Homebrew
brew install openjdk@17

# Set JAVA_HOME
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$PATH"

# Verify
java -version  # Should show Java 17
```

#### Step 2: Update Auth Service pom.xml

Change Java version back to 17:

```xml
<properties>
    <java.version>17</java.version>
</properties>
```

#### Step 3: Clean and Build

```bash
cd services/auth-service
mvn clean install
mvn spring-boot:run
```

### Option 3: Use Pre-built JAR Files

If JAR files were already built:

```bash
# Auth Service
cd services/auth-service
java -jar target/auth-service-1.0.0.jar

# In separate terminals for other services
cd services/search-service
go run cmd/main.go

cd services/booking-service
python3 -m uvicorn app.main:app --reload

cd services/payment-service
go run cmd/main.go

cd services/notification-service
python3 -m uvicorn app.main:app --port 8083 --reload
```

---

## Quick Start with Docker (Easiest)

### 1. Start Infrastructure

```bash
docker-compose -f docker-compose-infrastructure.yml up -d
```

**This starts:**
- PostgreSQL (port 5432)
- MongoDB (port 27017)
- Redis (port 6379)
- Kafka (ports 9092/9093)
- RabbitMQ (ports 5672/15672)
- Zookeeper (port 2181)

### 2. Start All Backend Services

```bash
docker-compose up -d
```

**This starts:**
- API Gateway (port 9000)
- Auth Service (port 8080)
- Search Service (port 8081)
- Booking Service (port 8000)
- Payment Service (port 8082)
- Notification Service (port 8083)

### 3. Verify Services

```bash
# Check all containers
docker-compose ps

# Test API Gateway
curl http://localhost:9000/health

# Test Auth Service
curl http://localhost:8080/actuator/health
```

### 4. Start Frontend

```bash
cd frontend
npm run dev
```

### 5. Test Login

Open http://localhost:3000 and try to login!

---

## Current Workaround (Without Docker)

Since the Auth Service has compilation issues, here's what's currently working:

### ✅ Working:
1. **API Gateway** - Running on port 9000
2. **CORS** - Enabled for frontend communication
3. **Frontend** - Can make requests to gateway

### ❌ Not Working:
1. **Auth Service** - Compilation error
2. **Login/Register** - Will fail because Auth Service is down

### Temporary Solution:

**Use Docker for backend services:**

```bash
# Stop the manually started gateway
# (Find the process and kill it if needed)

# Start everything with Docker
docker-compose -f docker-compose-infrastructure.yml up -d
docker-compose up -d

# Verify
curl http://localhost:9000/health
curl http://localhost:8080/actuator/health
```

---

## Testing the Integration

Once all services are running (via Docker or locally):

### 1. Test API Gateway

```bash
curl http://localhost:9000/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-12T..."
}
```

### 2. Test Auth Service

```bash
curl http://localhost:8080/actuator/health
```

**Expected Response:**
```json
{
  "status": "UP"
}
```

### 3. Test Registration

```bash
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@hotel.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "phoneNumber": "+1234567890"
  }'
```

**Expected Response:**
```json
{
  "token": "eyJhbGc...",
  "user": {
    "id": 1,
    "email": "test@hotel.com",
    "firstName": "Test",
    "lastName": "User",
    "role": "CUSTOMER"
  }
}
```

### 4. Test Login

```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@hotel.com",
    "password": "password123"
  }'
```

### 5. Test Frontend

1. Open http://localhost:3000
2. Click "Login"
3. Enter credentials
4. Should redirect to dashboard

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 9000
lsof -i :9000

# Kill the process
kill -9 <PID>
```

### Docker Services Not Starting

```bash
# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart auth-service

# Rebuild and restart
docker-compose up -d --build
```

### Database Connection Issues

```bash
# Check PostgreSQL
docker exec -it hotel-postgres psql -U admin -d hotel_db

# Check MongoDB
docker exec -it hotel-mongodb mongosh

# Check if databases exist
docker-compose -f docker-compose-infrastructure.yml ps
```

### CORS Errors

Make sure:
1. API Gateway is running
2. Frontend URL is correct in gateway/.env
3. Browser cache is cleared

```bash
# Check CORS headers
curl -v -H "Origin: http://localhost:3000" \
  http://localhost:9000/health
```

---

## Recommended Approach

**For Development:**
1. Use Docker for all backend services
2. Run frontend locally with `npm run dev`
3. This avoids Java/Maven/Go/Python setup issues

**Commands:**
```bash
# Terminal 1: Start infrastructure
docker-compose -f docker-compose-infrastructure.yml up -d

# Terminal 2: Start backend services
docker-compose up -d

# Terminal 3: Start frontend
cd frontend && npm run dev

# Terminal 4: Monitor logs
docker-compose logs -f
```

**Access:**
- Frontend: http://localhost:3000
- API Gateway: http://localhost:9000
- Auth Service: http://localhost:8080
- RabbitMQ UI: http://localhost:15672 (guest/guest)

---

## Next Steps

1. **Fix Lombok Issue** (if you want to run locally):
   - Install Java 17
   - Update pom.xml
   - Rebuild

2. **Or Use Docker** (recommended):
   - `docker-compose up -d`
   - Everything works out of the box

3. **Test Integration**:
   - Register a user
   - Login
   - Search hotels
   - Create booking

---

## Summary

**Current State:**
- ✅ API Gateway running (port 9000)
- ✅ CORS enabled
- ✅ Frontend ready
- ❌ Auth Service compilation error (Lombok + Java 21)

**Recommended Solution:**
Use Docker to run all backend services:
```bash
docker-compose -f docker-compose-infrastructure.yml up -d
docker-compose up -d
cd frontend && npm run dev
```

**Then test at:** http://localhost:3000

---

Need help? Check the logs:
```bash
docker-compose logs -f auth-service
```

