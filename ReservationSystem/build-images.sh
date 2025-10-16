#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Building Docker Images for Hotel Reservation System${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Build Auth Service
echo -e "${YELLOW}📦 Building Auth Service...${NC}"
cd services/auth-service
docker build -t auth-service:latest .
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
docker build -t search-service:latest .
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
docker build -t booking-service:latest .
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
docker build -t payment-service:latest .
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
docker build -t notification-service:latest .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Notification Service built successfully${NC}"
else
    echo -e "${RED}✗ Notification Service build failed${NC}"
    exit 1
fi
cd ../..

# Build Gateway
echo -e "${YELLOW}📦 Building Gateway...${NC}"
cd gateway
docker build -t gateway:latest .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Gateway built successfully${NC}"
else
    echo -e "${RED}✗ Gateway build failed${NC}"
    exit 1
fi
cd ..

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ All images built successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 Built Images:${NC}"
docker images | grep -E "auth-service|search-service|booking-service|payment-service|notification-service|gateway" | grep latest

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Start Minikube: ${GREEN}minikube start${NC}"
echo -e "  2. Load images to Minikube: ${GREEN}./load-images-to-minikube.sh${NC}"
echo -e "  3. Deploy with Helm: ${GREEN}helm install hotel-reservation ./helm/hotel-reservation${NC}"
echo ""

