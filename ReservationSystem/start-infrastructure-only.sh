#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Starting Infrastructure for Hotel Reservation System${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Start infrastructure
echo -e "${YELLOW}🚀 Starting infrastructure services...${NC}"
docker-compose -f docker-compose-infrastructure.yml up -d

echo ""
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 15

echo ""
echo -e "${BLUE}🏥 Running health checks...${NC}"
echo ""

# PostgreSQL
echo -n "PostgreSQL: "
if docker exec hotel-postgres pg_isready -U admin > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not Ready${NC}"
fi

# MongoDB
echo -n "MongoDB: "
if docker exec hotel-mongo mongosh --quiet --eval "db.adminCommand('ping').ok" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not Ready${NC}"
fi

# Redis
echo -n "Redis: "
if docker exec hotel-redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not Ready${NC}"
fi

# RabbitMQ
echo -n "RabbitMQ: "
if docker exec hotel-rabbitmq rabbitmq-diagnostics ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not Ready${NC}"
fi

# Kafka
echo -n "Kafka: "
if docker exec hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not Ready${NC}"
fi

echo ""
echo -e "${BLUE}📝 Initializing MongoDB with sample data...${NC}"
docker exec -i hotel-mongo mongosh -u admin -p admin < init-mongo.js > /dev/null 2>&1
echo -e "${GREEN}✓ MongoDB initialized${NC}"

echo ""
echo -e "${BLUE}📝 Creating Kafka topics...${NC}"

# Create booking-events topic
docker exec hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic booking-events \
  --partitions 3 \
  --replication-factor 1 \
  --if-not-exists > /dev/null 2>&1

# Create payment-events topic
docker exec hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic payment-events \
  --partitions 3 \
  --replication-factor 1 \
  --if-not-exists > /dev/null 2>&1

echo -e "${GREEN}✓ Kafka topics created${NC}"

echo ""
echo -e "${BLUE}📝 Creating RabbitMQ queues...${NC}"

# Wait for RabbitMQ to be fully ready
sleep 5

# Create booking_notifications queue
docker exec hotel-rabbitmq rabbitmqadmin declare queue \
  name=booking_notifications \
  durable=true > /dev/null 2>&1

# Create payment_notifications queue
docker exec hotel-rabbitmq rabbitmqadmin declare queue \
  name=payment_notifications \
  durable=true > /dev/null 2>&1

echo -e "${GREEN}✓ RabbitMQ queues created${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Infrastructure is ready!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📌 Connection Details:${NC}"
echo ""
echo -e "  ${YELLOW}PostgreSQL:${NC}"
echo -e "    Host: ${GREEN}localhost:5432${NC}"
echo -e "    Database: ${GREEN}hotel_db${NC}"
echo -e "    User: ${GREEN}admin${NC} / Password: ${GREEN}admin${NC}"
echo -e "    Connection String: ${GREEN}postgresql://admin:admin@localhost:5432/hotel_db${NC}"
echo ""
echo -e "  ${YELLOW}MongoDB:${NC}"
echo -e "    Host: ${GREEN}localhost:27017${NC}"
echo -e "    User: ${GREEN}admin${NC} / Password: ${GREEN}admin${NC}"
echo -e "    Connection String: ${GREEN}mongodb://admin:admin@localhost:27017${NC}"
echo ""
echo -e "  ${YELLOW}Redis:${NC}"
echo -e "    Host: ${GREEN}localhost:6379${NC}"
echo -e "    Connection String: ${GREEN}redis://localhost:6379${NC}"
echo ""
echo -e "  ${YELLOW}Kafka:${NC}"
echo -e "    Bootstrap Servers: ${GREEN}localhost:9093${NC}"
echo -e "    Topics: ${GREEN}booking-events, payment-events${NC}"
echo ""
echo -e "  ${YELLOW}RabbitMQ:${NC}"
echo -e "    AMQP: ${GREEN}localhost:5672${NC}"
echo -e "    Management UI: ${GREEN}http://localhost:15672${NC} (admin/admin)"
echo -e "    Queues: ${GREEN}booking_notifications, payment_notifications${NC}"
echo ""

echo -e "${BLUE}🎯 Now you can run your services manually:${NC}"
echo ""
echo -e "  ${YELLOW}Auth Service:${NC}"
echo -e "    cd services/auth-service"
echo -e "    mvn spring-boot:run"
echo ""
echo -e "  ${YELLOW}Search Service:${NC}"
echo -e "    cd services/search-service"
echo -e "    go run cmd/main.go"
echo ""
echo -e "  ${YELLOW}Booking Service:${NC}"
echo -e "    cd services/booking-service"
echo -e "    uvicorn app.main:app --reload --port 8000"
echo ""
echo -e "  ${YELLOW}Payment Service:${NC}"
echo -e "    cd services/payment-service"
echo -e "    go run cmd/main.go"
echo ""
echo -e "  ${YELLOW}Notification Service:${NC}"
echo -e "    cd services/notification-service"
echo -e "    uvicorn app.main:app --reload --port 8083"
echo ""
echo -e "  ${YELLOW}Gateway:${NC}"
echo -e "    cd gateway"
echo -e "    npm start"
echo ""

echo -e "${BLUE}📊 View logs:${NC}"
echo -e "  docker-compose -f docker-compose-infrastructure.yml logs -f"
echo ""

echo -e "${BLUE}🛑 Stop infrastructure:${NC}"
echo -e "  docker-compose -f docker-compose-infrastructure.yml down"
echo ""

