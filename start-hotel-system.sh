#!/bin/bash

# Hotel Reservation System - Easy Start Script
# This script starts all necessary services and opens the application

set -e

echo "🚀 Starting Hotel Reservation System..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Minikube is running
echo -e "${BLUE}📋 Checking Minikube status...${NC}"
if ! minikube status > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Minikube is not running. Starting Minikube...${NC}"
    minikube start --memory=10240 --cpus=4 --disk-size=40g
else
    echo -e "${GREEN}✅ Minikube is running${NC}"
fi

echo ""

# Check if the Helm release is installed
echo -e "${BLUE}📋 Checking if Hotel Reservation System is deployed...${NC}"
if ! helm list -n hotel-reserve-dummy | grep -q hotel-reserve-dummy; then
    echo -e "${YELLOW}⚠️  Hotel Reservation System is not deployed.${NC}"
    echo -e "${YELLOW}   Please run the deployment script first:${NC}"
    echo -e "${YELLOW}   ./deploy-hotel-system.sh${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Hotel Reservation System is deployed${NC}"
fi

echo ""

# Wait for all pods to be ready
echo -e "${BLUE}📋 Waiting for all services to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=frontend -n hotel-reserve-dummy --timeout=60s > /dev/null 2>&1 || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gateway -n hotel-reserve-dummy --timeout=60s > /dev/null 2>&1 || true

echo -e "${GREEN}✅ All services are ready${NC}"
echo ""

# Kill any existing minikube service tunnels
echo -e "${BLUE}📋 Cleaning up old tunnels...${NC}"
pkill -f "minikube service" > /dev/null 2>&1 || true
sleep 2

echo ""
echo -e "${GREEN}🌐 Starting service tunnels...${NC}"
echo ""

# Start frontend tunnel in background
echo -e "${BLUE}Starting frontend tunnel...${NC}"
minikube service frontend -n hotel-reserve-dummy --url > /tmp/frontend-url.txt 2>&1 &
FRONTEND_PID=$!
sleep 3

# Start gateway tunnel in background
echo -e "${BLUE}Starting gateway tunnel...${NC}"
minikube service gateway -n hotel-reserve-dummy --url > /tmp/gateway-url.txt 2>&1 &
GATEWAY_PID=$!
sleep 3

# Get the URLs
FRONTEND_URL=$(head -1 /tmp/frontend-url.txt)
GATEWAY_URL=$(head -1 /tmp/gateway-url.txt)

echo ""
echo -e "${GREEN}✅ Hotel Reservation System is now running!${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📱 ACCESS YOUR APPLICATION:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}🌐 Frontend:${NC}  ${YELLOW}${FRONTEND_URL}${NC}"
echo -e "${BLUE}🔌 Gateway API:${NC}  ${YELLOW}${GATEWAY_URL}${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📝 IMPORTANT:${NC}"
echo -e "   - Keep this terminal window open to maintain the tunnels"
echo -e "   - Press Ctrl+C to stop the tunnels and exit"
echo ""
echo -e "${GREEN}🎯 TESTING THE APPLICATION:${NC}"
echo -e "   1. Open the frontend URL in your browser"
echo -e "   2. Register a new account or login"
echo -e "   3. Browse and search for hotels"
echo -e "   4. Create a booking"
echo -e "   5. View your reservations"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Open frontend in browser
echo -e "${BLUE}🌐 Opening frontend in browser...${NC}"
sleep 2
open "${FRONTEND_URL}" 2>/dev/null || xdg-open "${FRONTEND_URL}" 2>/dev/null || echo "Please open ${FRONTEND_URL} in your browser"

echo ""
echo -e "${GREEN}✅ System is ready! Press Ctrl+C to stop.${NC}"
echo ""

# Wait for user to press Ctrl+C
trap "echo ''; echo -e '${YELLOW}🛑 Stopping tunnels...${NC}'; kill $FRONTEND_PID $GATEWAY_PID 2>/dev/null; echo -e '${GREEN}✅ Tunnels stopped${NC}'; exit 0" INT

# Keep the script running
wait

