#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Loading Docker Images to Minikube${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo -e "${RED}✗ Minikube is not running. Starting Minikube...${NC}"
    minikube start
fi

echo -e "${GREEN}✓ Minikube is running${NC}"
echo ""

# Load images to Minikube
images=("auth-service:latest" "search-service:latest" "booking-service:latest" "payment-service:latest" "notification-service:latest" "gateway:latest")

for image in "${images[@]}"; do
    echo -e "${YELLOW}📦 Loading $image to Minikube...${NC}"
    minikube image load $image
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $image loaded successfully${NC}"
    else
        echo -e "${RED}✗ Failed to load $image${NC}"
    fi
    echo ""
done

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ All images loaded to Minikube!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 Images in Minikube:${NC}"
minikube image ls | grep -E "auth-service|search-service|booking-service|payment-service|notification-service|gateway"

echo ""
echo -e "${YELLOW}Next step:${NC}"
echo -e "  Deploy with Helm: ${GREEN}helm install hotel-reservation ./helm/hotel-reservation${NC}"
echo ""

