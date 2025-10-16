# Infrastructure Setup Guide

## 🚀 Running Infrastructure Services in Docker

This guide will help you run PostgreSQL, MongoDB, Redis, RabbitMQ, and Kafka in Docker while running your application services locally.

---

## 📋 Prerequisites

- Docker and Docker Compose installed
- Terminal/Command Line access

---

## 🏗️ Step 1: Start Infrastructure Services

### Start All Infrastructure Services

```bash
cd deploy
docker-compose -f docker-compose-infra.yml up -d
```

### Check Running Services

```bash
docker-compose -f docker-compose-infra.yml ps
```

### View Logs

```bash
# All services
docker-compose -f docker-compose-infra.yml logs -f

# Specific service
docker-compose -f docker-compose-infra.yml logs -f postgres
docker-compose -f docker-compose-infra.yml logs -f mongo
docker-compose -f docker-compose-infra.yml logs -f redis
docker-compose -f docker-compose-infra.yml logs -f kafka
docker-compose -f docker-compose-infra.yml logs -f rabbitmq
```

### Stop All Services

```bash
docker-compose -f docker-compose-infra.yml down
```

### Stop and Remove Volumes (Clean Slate)

```bash
docker-compose -f docker-compose-infra.yml down -v
```

---

## 🔌 Connection Details

### PostgreSQL
- **Host**: localhost
- **Port**: 5432
- **Database**: hotel_db
- **Username**: admin
- **Password**: admin
- **Connection String**: `postgresql://admin:admin@localhost:5432/hotel_db`

### MongoDB
- **Host**: localhost
- **Port**: 27017
- **Username**: admin
- **Password**: admin
- **Connection String**: `mongodb://admin:admin@localhost:27017`

### Redis
- **Host**: localhost
- **Port**: 6379
- **Connection String**: `redis://localhost:6379`

### Kafka
- **Bootstrap Servers**: localhost:9093
- **Internal (Docker)**: kafka:9092
- **Zookeeper**: localhost:2181

### RabbitMQ
- **AMQP Port**: localhost:5672
- **Management UI**: http://localhost:15672
- **Username**: admin
- **Password**: admin
- **Connection String**: `amqp://admin:admin@localhost:5672/`

---

## 🖥️ Terminal Commands to Access Services

### PostgreSQL

#### Connect to PostgreSQL CLI
```bash
docker exec -it hotel-postgres psql -U admin -d hotel_db
```

#### Common PostgreSQL Commands
```sql
-- List all databases
\l

-- Connect to hotel_db
\c hotel_db

-- List all tables
\dt

-- Describe a table
\d table_name

-- Show all users
SELECT * FROM users;

-- Create a test table
CREATE TABLE test (id SERIAL PRIMARY KEY, name VARCHAR(100));

-- Insert test data
INSERT INTO test (name) VALUES ('Test User');

-- Query data
SELECT * FROM test;

-- Exit
\q
```

#### Execute SQL from Terminal
```bash
# Run a query
docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT * FROM users;"

# Run SQL file
docker exec -i hotel-postgres psql -U admin -d hotel_db < your_script.sql
```

---

### MongoDB

#### Connect to MongoDB CLI
```bash
docker exec -it hotel-mongo mongosh -u admin -p admin
```

#### Common MongoDB Commands
```javascript
// Show all databases
show dbs

// Use hotel database
use hotel_db

// Show collections
show collections

// Insert a document
db.hotels.insertOne({
  name: "Grand Hotel",
  location: "New York",
  rating: 4.5
})

// Find all documents
db.hotels.find()

// Find with filter
db.hotels.find({ location: "New York" })

// Pretty print
db.hotels.find().pretty()

// Count documents
db.hotels.countDocuments()

// Exit
exit
```

#### Execute MongoDB Commands from Terminal
```bash
# Run a command
docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.hotels.find()"

# Run a JavaScript file
docker exec -i hotel-mongo mongosh -u admin -p admin < your_script.js
```

---

### Redis

#### Connect to Redis CLI
```bash
docker exec -it hotel-redis redis-cli
```

#### Common Redis Commands
```bash
# Set a key
SET mykey "Hello World"

# Get a key
GET mykey

# Set with expiration (seconds)
SETEX session:123 3600 "user_data"

# Check if key exists
EXISTS mykey

# Get all keys
KEYS *

# Delete a key
DEL mykey

# Get key type
TYPE mykey

# Set hash
HSET user:1 name "John" email "john@example.com"

# Get hash field
HGET user:1 name

# Get all hash fields
HGETALL user:1

# List all keys matching pattern
KEYS session:*

# Get database info
INFO

# Flush all data (careful!)
FLUSHALL

# Exit
exit
```

#### Execute Redis Commands from Terminal
```bash
# Run a command
docker exec -it hotel-redis redis-cli GET mykey

# Set a value
docker exec -it hotel-redis redis-cli SET test "value"

# Monitor all commands
docker exec -it hotel-redis redis-cli MONITOR
```

---

### Kafka

#### List Topics
```bash
docker exec -it hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list
```

#### Create a Topic
```bash
docker exec -it hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic booking-events \
  --partitions 3 \
  --replication-factor 1
```

#### Describe a Topic
```bash
docker exec -it hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic booking-events
```

#### Produce Messages
```bash
docker exec -it hotel-kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic booking-events
# Type messages and press Enter
# Press Ctrl+C to exit
```

#### Consume Messages
```bash
# From beginning
docker exec -it hotel-kafka kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic booking-events \
  --from-beginning

# Latest messages only
docker exec -it hotel-kafka kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic booking-events
```

#### Delete a Topic
```bash
docker exec -it hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --delete \
  --topic booking-events
```

---

### RabbitMQ

#### Access Management UI
Open browser: http://localhost:15672
- Username: admin
- Password: admin

#### Using rabbitmqadmin CLI

First, install rabbitmqadmin:
```bash
# Download rabbitmqadmin
docker exec -it hotel-rabbitmq rabbitmqadmin --help
```

#### List Queues
```bash
docker exec -it hotel-rabbitmq rabbitmqctl list_queues
```

#### List Exchanges
```bash
docker exec -it hotel-rabbitmq rabbitmqctl list_exchanges
```

#### List Bindings
```bash
docker exec -it hotel-rabbitmq rabbitmqctl list_bindings
```

#### Create Queue
```bash
docker exec -it hotel-rabbitmq rabbitmqadmin declare queue name=booking_notifications durable=true
```

#### Publish Message
```bash
docker exec -it hotel-rabbitmq rabbitmqadmin publish \
  exchange=amq.default \
  routing_key=booking_notifications \
  payload="Test message"
```

#### Get Messages
```bash
docker exec -it hotel-rabbitmq rabbitmqadmin get queue=booking_notifications
```

#### Purge Queue
```bash
docker exec -it hotel-rabbitmq rabbitmqadmin purge queue name=booking_notifications
```

#### Delete Queue
```bash
docker exec -it hotel-rabbitmq rabbitmqadmin delete queue name=booking_notifications
```

---

## 🔍 Health Checks

### Check All Services Health
```bash
# PostgreSQL
docker exec -it hotel-postgres pg_isready -U admin

# MongoDB
docker exec -it hotel-mongo mongosh --eval "db.adminCommand('ping')"

# Redis
docker exec -it hotel-redis redis-cli ping

# RabbitMQ
docker exec -it hotel-rabbitmq rabbitmq-diagnostics ping

# Kafka
docker exec -it hotel-kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

---

## 📊 Monitoring & Stats

### PostgreSQL Stats
```bash
docker exec -it hotel-postgres psql -U admin -d hotel_db -c "
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

### MongoDB Stats
```bash
docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.stats()"
```

### Redis Stats
```bash
docker exec -it hotel-redis redis-cli INFO stats
docker exec -it hotel-redis redis-cli INFO memory
```

### RabbitMQ Stats
```bash
docker exec -it hotel-rabbitmq rabbitmqctl status
docker exec -it hotel-rabbitmq rabbitmqctl list_connections
```

---

## 🗄️ Data Backup & Restore

### PostgreSQL Backup
```bash
# Backup
docker exec -it hotel-postgres pg_dump -U admin hotel_db > backup.sql

# Restore
docker exec -i hotel-postgres psql -U admin hotel_db < backup.sql
```

### MongoDB Backup
```bash
# Backup
docker exec -it hotel-mongo mongodump -u admin -p admin --out /backup

# Restore
docker exec -it hotel-mongo mongorestore -u admin -p admin /backup
```

### Redis Backup
```bash
# Trigger save
docker exec -it hotel-redis redis-cli SAVE

# Copy dump file
docker cp hotel-redis:/data/dump.rdb ./redis-backup.rdb
```

---

## 🧹 Cleanup Commands

### Remove All Containers
```bash
docker-compose -f docker-compose-infra.yml down
```

### Remove Containers and Volumes
```bash
docker-compose -f docker-compose-infra.yml down -v
```

### Remove Specific Volume
```bash
docker volume rm deploy_postgres_data
docker volume rm deploy_mongo_data
docker volume rm deploy_redis_data
docker volume rm deploy_kafka_data
docker volume rm deploy_rabbitmq_data
```

### View Disk Usage
```bash
docker system df
```

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Find process using port
lsof -i :5432  # PostgreSQL
lsof -i :27017 # MongoDB
lsof -i :6379  # Redis
lsof -i :9092  # Kafka
lsof -i :5672  # RabbitMQ

# Kill process
kill -9 <PID>
```

### Container Won't Start
```bash
# Check logs
docker logs hotel-postgres
docker logs hotel-mongo
docker logs hotel-redis
docker logs hotel-kafka
docker logs hotel-rabbitmq

# Restart specific service
docker restart hotel-postgres
```

### Network Issues
```bash
# Inspect network
docker network inspect deploy_hotel-network

# Recreate network
docker network rm deploy_hotel-network
docker network create deploy_hotel-network
```

---

## 📝 Quick Reference Card

```bash
# START INFRASTRUCTURE
cd deploy && docker-compose -f docker-compose-infra.yml up -d

# STOP INFRASTRUCTURE
cd deploy && docker-compose -f docker-compose-infra.yml down

# POSTGRES CLI
docker exec -it hotel-postgres psql -U admin -d hotel_db

# MONGO CLI
docker exec -it hotel-mongo mongosh -u admin -p admin

# REDIS CLI
docker exec -it hotel-redis redis-cli

# RABBITMQ UI
http://localhost:15672 (admin/admin)

# KAFKA TOPICS
docker exec -it hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list

# VIEW LOGS
docker-compose -f docker-compose-infra.yml logs -f

# CHECK STATUS
docker-compose -f docker-compose-infra.yml ps
```

---

## ✅ Verification Checklist

After starting infrastructure, verify each service:

- [ ] PostgreSQL: `docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT 1;"`
- [ ] MongoDB: `docker exec -it hotel-mongo mongosh -u admin -p admin --eval "db.version()"`
- [ ] Redis: `docker exec -it hotel-redis redis-cli ping`
- [ ] RabbitMQ: Open http://localhost:15672
- [ ] Kafka: `docker exec -it hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list`

All services should respond successfully! ✨

