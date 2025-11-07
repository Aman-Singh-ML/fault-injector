#!/bin/bash

# Build Docker images for Minikube
# This script builds all images using Minikube's Docker daemon

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Building Docker Images for Minikube${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo -e "${RED}✗ Minikube is not running. Please start Minikube first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Minikube is running${NC}"
echo ""

# Set Docker environment to use Minikube's Docker daemon
echo -e "${YELLOW}🔧 Configuring Docker to use Minikube's daemon...${NC}"
eval $(minikube docker-env)
echo -e "${GREEN}✓ Docker configured to use Minikube's daemon${NC}"
echo ""

# Build Frontend
echo -e "${YELLOW}📦 Building Frontend...${NC}"
cd frontend
docker build -t amrita0909/hotel-frontend:amrita .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend built successfully${NC}"
else
    echo -e "${RED}✗ Frontend build failed${NC}"
    exit 1
fi
cd ..

# Build Gateway
echo -e "${YELLOW}📦 Building Gateway...${NC}"
cd gateway
docker build -t amrita0909/hotel-gateway:amrita .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Gateway built successfully${NC}"
else
    echo -e "${RED}✗ Gateway build failed${NC}"
    exit 1
fi
cd ..

# Build Auth Service
echo -e "${YELLOW}📦 Building Auth Service...${NC}"
cd services/auth-service
docker build -t amrita0909/hotel-auth-service:amrita .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Auth Service built successfully${NC}"
else
    echo -e "${RED}✗ Auth Service build failed${NC}"
    exit 1
fi
cd ../..

# Build Search Service
echo -e "${YELLOW}📦 Building Search Service...${NC}"
cd services/search-service
docker build -t amrita0909/hotel-search-service:amrita .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Search Service built successfully${NC}"
else
    echo -e "${RED}✗ Search Service build failed${NC}"
    exit 1
fi
cd ../..

# Build Booking Service
echo -e "${YELLOW}📦 Building Booking Service...${NC}"
cd services/booking-service
docker build -t amrita0909/hotel-booking-service:amrita .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Booking Service built successfully${NC}"
else
    echo -e "${RED}✗ Booking Service build failed${NC}"
    exit 1
fi
cd ../..

# Build Payment Service
echo -e "${YELLOW}📦 Building Payment Service...${NC}"
cd services/payment-service
docker build -t amrita0909/hotel-payment-service:amrita .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Payment Service built successfully${NC}"
else
    echo -e "${RED}✗ Payment Service build failed${NC}"
    exit 1
fi
cd ../..

# Build Notification Service
echo -e "${YELLOW}📦 Building Notification Service...${NC}"
cd services/notification-service
docker build -t amrita0909/hotel-notification-service:amrita .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Notification Service built successfully${NC}"
else
    echo -e "${RED}✗ Notification Service build failed${NC}"
    exit 1
fi
cd ../..

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ All images built successfully in Minikube!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 Built Images:${NC}"
docker images | grep -E "amrita0909/hotel"

echo ""
echo -e "${YELLOW}Next step:${NC}"
echo -e "  Deploy with Helm: ${GREEN}helm upgrade --install hotel-reserve-dummy ./helm/hotel-reservation-system -n hotel-reserve-dummy${NC}"
echo ""

