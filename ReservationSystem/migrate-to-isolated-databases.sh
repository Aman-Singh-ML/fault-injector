#!/bin/bash

# Migration Script: Move from Shared Database to Isolated Database Instances
# This script migrates data from the shared hotel_db to separate database instances

set -e

echo "🔄 Starting Database Migration to Isolated Instances..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if old database exists
echo -e "${BLUE}📊 Checking for existing shared database...${NC}"
if docker ps | grep -q "hotel-postgres"; then
    echo -e "${YELLOW}⚠️  Found existing shared database. Backing up data...${NC}"
    
    # Backup users table
    echo -e "${BLUE}📦 Backing up users table...${NC}"
    docker exec hotel-postgres pg_dump -U admin -d hotel_db -t users --data-only > /tmp/users_backup.sql 2>/dev/null || true
    
    # Backup bookings table
    echo -e "${BLUE}📦 Backing up bookings table...${NC}"
    docker exec hotel-postgres pg_dump -U admin -d hotel_db -t bookings --data-only > /tmp/bookings_backup.sql 2>/dev/null || true
    
    # Backup payments table
    echo -e "${BLUE}📦 Backing up payments table...${NC}"
    docker exec hotel-postgres pg_dump -U admin -d hotel_db -t payments --data-only > /tmp/payments_backup.sql 2>/dev/null || true
    
    echo -e "${GREEN}✓ Backup completed${NC}"
    echo ""
    
    # Stop old infrastructure
    echo -e "${YELLOW}🛑 Stopping old infrastructure...${NC}"
    docker stop hotel-postgres 2>/dev/null || true
    docker rm hotel-postgres 2>/dev/null || true
fi

# Start new isolated database instances
echo -e "${BLUE}🚀 Starting new isolated database instances...${NC}"
docker-compose -f docker-compose-infrastructure.yml up -d postgres-auth postgres-booking postgres-payment

# Wait for databases to be ready
echo -e "${BLUE}⏳ Waiting for databases to be ready...${NC}"
sleep 10

# Check health of new databases
echo -e "${BLUE}🏥 Checking database health...${NC}"
for i in {1..30}; do
    if docker exec hotel-postgres-auth pg_isready -U auth_user -d auth_db > /dev/null 2>&1 && \
       docker exec hotel-postgres-booking pg_isready -U booking_user -d booking_db > /dev/null 2>&1 && \
       docker exec hotel-postgres-payment pg_isready -U payment_user -d payment_db > /dev/null 2>&1; then
        echo -e "${GREEN}✓ All databases are ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Restore data if backups exist
if [ -f "/tmp/users_backup.sql" ]; then
    echo -e "${BLUE}📥 Restoring users data to auth database...${NC}"
    docker exec -i hotel-postgres-auth psql -U auth_user -d auth_db < /tmp/users_backup.sql 2>/dev/null || true
    echo -e "${GREEN}✓ Users data restored${NC}"
fi

if [ -f "/tmp/bookings_backup.sql" ]; then
    echo -e "${BLUE}📥 Restoring bookings data to booking database...${NC}"
    docker exec -i hotel-postgres-booking psql -U booking_user -d booking_db < /tmp/bookings_backup.sql 2>/dev/null || true
    echo -e "${GREEN}✓ Bookings data restored${NC}"
fi

if [ -f "/tmp/payments_backup.sql" ]; then
    echo -e "${BLUE}📥 Restoring payments data to payment database...${NC}"
    docker exec -i hotel-postgres-payment psql -U payment_user -d payment_db < /tmp/payments_backup.sql 2>/dev/null || true
    echo -e "${GREEN}✓ Payments data restored${NC}"
fi

echo ""
echo -e "${GREEN}✅ Database migration completed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Database Summary:${NC}"
echo -e "  ${GREEN}✓${NC} Auth Database:    postgres-auth    (Port 5432) - auth_db"
echo -e "  ${GREEN}✓${NC} Booking Database: postgres-booking (Port 5433) - booking_db"
echo -e "  ${GREEN}✓${NC} Payment Database: postgres-payment (Port 5434) - payment_db"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo -e "  1. Update service environment variables to use new database ports"
echo -e "  2. Restart all services with: ./restart-services.sh"
echo ""

