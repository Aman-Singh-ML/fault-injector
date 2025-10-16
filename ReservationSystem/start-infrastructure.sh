#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Hotel Reservation System - Infrastructure Startup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Navigate to deploy directory
cd deploy

echo -e "${YELLOW}🚀 Starting infrastructure services...${NC}"
docker-compose -f docker-compose-infra.yml up -d

echo ""
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

echo ""
echo -e "${BLUE}📊 Checking service status...${NC}"
docker-compose -f docker-compose-infra.yml ps

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
echo -e "${BLUE}📝 Creating required Kafka topics...${NC}"

# Create Kafka topics
docker exec hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic booking-events \
  --partitions 3 \
  --replication-factor 1 \
  --if-not-exists > /dev/null 2>&1

docker exec hotel-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic payment-events \
  --partitions 3 \
  --replication-factor 1 \
  --if-not-exists > /dev/null 2>&1

echo -e "${GREEN}✓ Kafka topics created${NC}"

echo ""
echo -e "${BLUE}📝 Creating required RabbitMQ queues...${NC}"

# Create RabbitMQ queues
docker exec hotel-rabbitmq rabbitmqadmin declare queue \
  name=booking_notifications \
  durable=true > /dev/null 2>&1

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
echo -e "    Host: localhost:5432"
echo -e "    Database: hotel_db"
echo -e "    User: admin / Password: admin"
echo -e "    Connect: ${GREEN}docker exec -it hotel-postgres psql -U admin -d hotel_db${NC}"
echo ""
echo -e "  ${YELLOW}MongoDB:${NC}"
echo -e "    Host: localhost:27017"
echo -e "    User: admin / Password: admin"
echo -e "    Connect: ${GREEN}docker exec -it hotel-mongo mongosh -u admin -p admin${NC}"
echo ""
echo -e "  ${YELLOW}Redis:${NC}"
echo -e "    Host: localhost:6379"
echo -e "    Connect: ${GREEN}docker exec -it hotel-redis redis-cli${NC}"
echo ""
echo -e "  ${YELLOW}Kafka:${NC}"
echo -e "    Bootstrap: localhost:9093"
echo -e "    Topics: ${GREEN}docker exec -it hotel-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list${NC}"
echo ""
echo -e "  ${YELLOW}RabbitMQ:${NC}"
echo -e "    AMQP: localhost:5672"
echo -e "    Management UI: ${GREEN}http://localhost:15672${NC} (admin/admin)"
echo ""

echo -e "${BLUE}📚 Next Steps:${NC}"
echo -e "  1. Start your application services (see LOCAL_DEVELOPMENT_GUIDE.md)"
echo -e "  2. View terminal commands: ${GREEN}cat TERMINAL_COMMANDS_REFERENCE.txt${NC}"
echo -e "  3. View logs: ${GREEN}docker-compose -f docker-compose-infra.yml logs -f${NC}"
echo ""

