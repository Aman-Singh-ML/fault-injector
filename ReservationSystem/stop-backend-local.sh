#!/bin/bash

# Hotel Reservation System - Stop Backend Services Script

echo "🛑 Stopping Hotel Reservation System Backend Services"
echo "======================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to kill process on port
kill_port() {
    local port=$1
    local service=$2
    
    local pid=$(lsof -ti:$port)
    if [ ! -z "$pid" ]; then
        echo -e "${YELLOW}Stopping $service (port $port, PID: $pid)...${NC}"
        kill -9 $pid 2>/dev/null
        echo -e "${GREEN}✅ $service stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  $service not running on port $port${NC}"
    fi
}

# Stop all services
kill_port 9000 "API Gateway"
kill_port 8080 "Auth Service"
kill_port 8081 "Search Service"
kill_port 8000 "Booking Service"
kill_port 8082 "Payment Service"
kill_port 8083 "Notification Service"

echo ""
echo -e "${GREEN}🎉 All backend services stopped!${NC}"
echo ""
echo "💡 Infrastructure (Docker) is still running."
echo "   To stop infrastructure:"
echo "   docker-compose -f docker-compose-infrastructure.yml down"
echo ""

