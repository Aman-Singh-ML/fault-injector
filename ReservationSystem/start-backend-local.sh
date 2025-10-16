#!/bin/bash

# Hotel Reservation System - Local Backend Startup Script
# This script starts all backend services for local development

set -e

echo "🚀 Starting Hotel Reservation System Backend Services"
echo "======================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if infrastructure is running
echo -e "${YELLOW}📋 Checking infrastructure...${NC}"
if ! docker ps | grep -q hotel-postgres; then
    echo -e "${RED}❌ Infrastructure not running!${NC}"
    echo "Please start infrastructure first:"
    echo "  docker-compose -f docker-compose-infrastructure.yml up -d"
    exit 1
fi
echo -e "${GREEN}✅ Infrastructure is running${NC}"
echo ""

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port $1 is already in use${NC}"
        return 1
    fi
    return 0
}

# Function to start service in background
start_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    local start_command=$4
    
    echo -e "${YELLOW}🔧 Starting $service_name on port $port...${NC}"
    
    if ! check_port $port; then
        echo -e "${YELLOW}   Skipping (already running)${NC}"
        return
    fi
    
    cd "$service_dir"
    
    # Start service in background
    nohup $start_command > "../logs/${service_name}.log" 2>&1 &
    local pid=$!
    
    echo -e "${GREEN}✅ $service_name started (PID: $pid)${NC}"
    echo "   Logs: logs/${service_name}.log"
    
    cd - > /dev/null
}

# Create logs directory
mkdir -p logs

echo "🎯 Starting Services..."
echo ""

# 1. Start API Gateway (Node.js)
echo -e "${YELLOW}1️⃣  API Gateway${NC}"
if check_port 9000; then
    cd gateway
    if [ ! -d "node_modules" ]; then
        echo "   Installing dependencies..."
        npm install > /dev/null 2>&1
    fi
    nohup npm start > ../logs/gateway.log 2>&1 &
    echo -e "${GREEN}✅ API Gateway started (PID: $!)${NC}"
    echo "   URL: http://localhost:9000"
    echo "   Logs: logs/gateway.log"
    cd ..
else
    echo -e "${YELLOW}   Skipping (already running)${NC}"
fi
echo ""

# 2. Start Auth Service (Java/Spring Boot)
echo -e "${YELLOW}2️⃣  Auth Service${NC}"
if check_port 8080; then
    echo "   Building and starting Auth Service..."
    echo "   This may take a minute..."
    cd services/auth-service
    nohup ./mvnw spring-boot:run > ../../logs/auth-service.log 2>&1 &
    echo -e "${GREEN}✅ Auth Service starting (PID: $!)${NC}"
    echo "   URL: http://localhost:8080"
    echo "   Logs: logs/auth-service.log"
    cd ../..
else
    echo -e "${YELLOW}   Skipping (already running)${NC}"
fi
echo ""

# 3. Start Search Service (Go)
echo -e "${YELLOW}3️⃣  Search Service${NC}"
if check_port 8081; then
    cd services/search-service
    if [ ! -f "search-service" ]; then
        echo "   Building Go binary..."
        go build -o search-service cmd/main.go
    fi
    nohup ./search-service > ../../logs/search-service.log 2>&1 &
    echo -e "${GREEN}✅ Search Service started (PID: $!)${NC}"
    echo "   URL: http://localhost:8081"
    echo "   Logs: logs/search-service.log"
    cd ../..
else
    echo -e "${YELLOW}   Skipping (already running)${NC}"
fi
echo ""

# 4. Start Booking Service (Python/FastAPI)
echo -e "${YELLOW}4️⃣  Booking Service${NC}"
if check_port 8000; then
    cd services/booking-service
    if [ ! -d "venv" ]; then
        echo "   Creating virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt > /dev/null 2>&1
    else
        source venv/bin/activate
    fi
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > ../../logs/booking-service.log 2>&1 &
    echo -e "${GREEN}✅ Booking Service started (PID: $!)${NC}"
    echo "   URL: http://localhost:8000"
    echo "   Logs: logs/booking-service.log"
    deactivate
    cd ../..
else
    echo -e "${YELLOW}   Skipping (already running)${NC}"
fi
echo ""

# 5. Start Payment Service (Go)
echo -e "${YELLOW}5️⃣  Payment Service${NC}"
if check_port 8082; then
    cd services/payment-service
    if [ ! -f "payment-service" ]; then
        echo "   Building Go binary..."
        go build -o payment-service cmd/main.go
    fi
    nohup ./payment-service > ../../logs/payment-service.log 2>&1 &
    echo -e "${GREEN}✅ Payment Service started (PID: $!)${NC}"
    echo "   URL: http://localhost:8082"
    echo "   Logs: logs/payment-service.log"
    cd ../..
else
    echo -e "${YELLOW}   Skipping (already running)${NC}"
fi
echo ""

# 6. Start Notification Service (Python/FastAPI)
echo -e "${YELLOW}6️⃣  Notification Service${NC}"
if check_port 8083; then
    cd services/notification-service
    if [ ! -d "venv" ]; then
        echo "   Creating virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt > /dev/null 2>&1
    else
        source venv/bin/activate
    fi
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8083 > ../../logs/notification-service.log 2>&1 &
    echo -e "${GREEN}✅ Notification Service started (PID: $!)${NC}"
    echo "   URL: http://localhost:8083"
    echo "   Logs: logs/notification-service.log"
    deactivate
    cd ../..
else
    echo -e "${YELLOW}   Skipping (already running)${NC}"
fi
echo ""

echo "======================================================"
echo -e "${GREEN}🎉 All services started!${NC}"
echo ""
echo "📡 Service URLs:"
echo "   • API Gateway:    http://localhost:9000"
echo "   • Auth Service:   http://localhost:8080"
echo "   • Search Service: http://localhost:8081"
echo "   • Booking Service: http://localhost:8000"
echo "   • Payment Service: http://localhost:8082"
echo "   • Notification:   http://localhost:8083"
echo ""
echo "📊 Monitor logs:"
echo "   tail -f logs/*.log"
echo ""
echo "🛑 Stop all services:"
echo "   ./stop-backend-local.sh"
echo ""
echo "⏳ Services may take 30-60 seconds to fully start..."
echo "   Check logs for startup progress"
echo ""

