# 🚀 Quick Start Guide

## Overview

This guide will get your Hotel Reservation System up and running in **5 minutes**!

---

## ⚡ Super Quick Start

### Step 1: Start Infrastructure (30 seconds)

```bash
# Make script executable (first time only)
chmod +x start-infrastructure.sh

# Start all infrastructure services
./start-infrastructure.sh
```

This will start:
- ✅ PostgreSQL (localhost:5432)
- ✅ MongoDB (localhost:27017)
- ✅ Redis (localhost:6379)
- ✅ Kafka (localhost:9093)
- ✅ RabbitMQ (localhost:5672)

### Step 2: Verify Infrastructure (10 seconds)

```bash
# Check all services are running
cd deploy
docker-compose -f docker-compose-infra.yml ps
```

You should see all 5 services with status "Up".

### Step 3: Run Your Services Locally

Open **6 separate terminal windows** and run:

#### Terminal 1: Auth Service
```bash
cd services/auth-service
mvn spring-boot:run
```
**URL:** http://localhost:8080

#### Terminal 2: Search Service
```bash
cd services/search-service
go run cmd/main.go
```
**URL:** http://localhost:8081

#### Terminal 3: Booking Service
```bash
cd services/booking-service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```
**URL:** http://localhost:8000

#### Terminal 4: Payment Service
```bash
cd services/payment-service
go run cmd/main.go
```
**URL:** http://localhost:8082

#### Terminal 5: Notification Service
```bash
cd services/notification-service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8083
```
**URL:** http://localhost:8083

#### Terminal 6: API Gateway
```bash
cd gateway
npm install
npm start
```
**URL:** http://localhost:9000

---

## 🧪 Test Your Setup

### 1. Health Checks

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

# Gateway
curl http://localhost:9000/
```

### 2. Register a User

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

### 3. Login

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 4. Search Hotels

```bash
curl "http://localhost:8081/search?location=NewYork&checkIn=2024-01-15&checkOut=2024-01-20"
```

---

## 🗄️ Access Databases

### PostgreSQL
```bash
docker exec -it hotel-postgres psql -U admin -d hotel_db
```

### MongoDB
```bash
docker exec -it hotel-mongo mongosh -u admin -p admin
```

### Redis
```bash
docker exec -it hotel-redis redis-cli
```

### RabbitMQ Management UI
Open browser: http://localhost:15672
- Username: `admin`
- Password: `admin`

---

## 🛑 Stop Everything

### Stop Infrastructure
```bash
./stop-infrastructure.sh
```

### Stop Services
Press `Ctrl+C` in each terminal window running a service.

---

## 📚 Detailed Guides

- **Infrastructure Commands:** See `INFRASTRUCTURE_SETUP.md`
- **Terminal Commands:** See `TERMINAL_COMMANDS_REFERENCE.txt`
- **Local Development:** See `LOCAL_DEVELOPMENT_GUIDE.md`

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Find and kill process
lsof -i :8080
kill -9 <PID>
```

### Service Won't Start
```bash
# Check infrastructure logs
cd deploy
docker-compose -f docker-compose-infra.yml logs -f
```

### Database Connection Failed
```bash
# Verify PostgreSQL is running
docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT 1;"

# Verify MongoDB is running
docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.version()"
```

---

## ✅ Checklist

Before running services, ensure:

- [ ] Docker is running
- [ ] Infrastructure started: `./start-infrastructure.sh`
- [ ] All 5 infrastructure services are "Up"
- [ ] PostgreSQL accessible: `docker exec -it hotel-postgres psql -U admin -d hotel_db`
- [ ] MongoDB accessible: `docker exec -it hotel-mongo mongosh -u admin -p admin`
- [ ] Redis accessible: `docker exec -it hotel-redis redis-cli ping`
- [ ] RabbitMQ UI accessible: http://localhost:15672
- [ ] Kafka topics created

---

## 🎯 Service Ports Reference

| Service | Port | Health Check |
|---------|------|--------------|
| Auth Service | 8080 | http://localhost:8080/actuator/health |
| Search Service | 8081 | http://localhost:8081/health |
| Booking Service | 8000 | http://localhost:8000/health |
| Payment Service | 8082 | http://localhost:8082/health |
| Notification Service | 8083 | http://localhost:8083/health |
| API Gateway | 9000 | http://localhost:9000/ |
| PostgreSQL | 5432 | - |
| MongoDB | 27017 | - |
| Redis | 6379 | - |
| Kafka | 9093 | - |
| RabbitMQ | 5672 | - |
| RabbitMQ UI | 15672 | http://localhost:15672 |

---

## 🎉 You're Ready!

Your Hotel Reservation System is now running! Start developing and testing your microservices.

**Happy Coding! 🚀**

