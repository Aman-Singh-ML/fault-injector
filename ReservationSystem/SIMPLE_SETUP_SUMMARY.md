# ✅ Simple Infrastructure Setup - Summary

## What I've Created

I've set up a **simple Docker-based infrastructure** for your Hotel Reservation System. You'll run ONLY the databases and message brokers in Docker, and run your application services manually from the command line.

---

## 📦 Files Created

1. **`docker-compose-infrastructure.yml`** - Docker Compose file with ONLY infrastructure
   - PostgreSQL
   - MongoDB
   - Redis
   - Kafka + Zookeeper
   - RabbitMQ

2. **`init-db.sql`** - PostgreSQL initialization script
   - Creates tables for users, bookings, payments
   - Adds sample test users
   - Creates indexes

3. **`init-mongo.js`** - MongoDB initialization script
   - Creates sample hotels
   - Adds indexes for search

4. **`start-infrastructure-only.sh`** - One-command startup script
   - Starts all infrastructure
   - Runs health checks
   - Creates Kafka topics
   - Creates RabbitMQ queues
   - Shows connection details

5. **`RUN_SERVICES_GUIDE.md`** - Complete guide for running services manually

6. **Updated `.env.example` files** for all services with correct connection strings

---

## 🚀 How to Use

### Step 1: Start Infrastructure

```bash
./start-infrastructure-only.sh
```

This starts:
- ✅ PostgreSQL on localhost:5432
- ✅ MongoDB on localhost:27017
- ✅ Redis on localhost:6379
- ✅ Kafka on localhost:9093
- ✅ RabbitMQ on localhost:5672

### Step 2: Run Your Services Manually

Open 6 separate terminal windows:

**Terminal 1 - Auth Service:**
```bash
cd services/auth-service
mvn spring-boot:run
```

**Terminal 2 - Search Service:**
```bash
cd services/search-service
go run cmd/main.go
```

**Terminal 3 - Booking Service:**
```bash
cd services/booking-service
uvicorn app.main:app --reload --port 8000
```

**Terminal 4 - Payment Service:**
```bash
cd services/payment-service
go run cmd/main.go
```

**Terminal 5 - Notification Service:**
```bash
cd services/notification-service
uvicorn app.main:app --reload --port 8083
```

**Terminal 6 - Gateway:**
```bash
cd gateway
npm start
```

---

## 🔌 Connection Details

| Service | Host | Port | Credentials |
|---------|------|------|-------------|
| PostgreSQL | localhost | 5432 | admin / admin |
| MongoDB | localhost | 27017 | admin / admin |
| Redis | localhost | 6379 | - |
| Kafka | localhost | 9093 | - |
| RabbitMQ | localhost | 5672 | admin / admin |
| RabbitMQ UI | localhost | 15672 | admin / admin |

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

### RabbitMQ UI
Open browser: http://localhost:15672 (admin/admin)

---

## 🛑 Stop Infrastructure

```bash
docker-compose -f docker-compose-infrastructure.yml down
```

---

## 📚 Documentation

- **Complete Guide:** `RUN_SERVICES_GUIDE.md`
- **This Summary:** `SIMPLE_SETUP_SUMMARY.md`

---

**That's it! Simple and clean!** 🎉

