#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Hotel Reservation System - Infrastructure Shutdown${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Navigate to deploy directory
cd deploy

echo -e "${YELLOW}🛑 Stopping infrastructure services...${NC}"
docker-compose -f docker-compose-infra.yml down

echo ""
echo -e "${GREEN}✓ All infrastructure services stopped${NC}"
echo ""

# Ask if user wants to remove volumes
read -p "Do you want to remove data volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${YELLOW}🗑️  Removing volumes...${NC}"
    docker-compose -f docker-compose-infra.yml down -v
    echo -e "${GREEN}✓ Volumes removed${NC}"
else
    echo -e "${BLUE}ℹ️  Volumes preserved. Data will persist on next startup.${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Infrastructure shutdown complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

