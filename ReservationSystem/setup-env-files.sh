#!/bin/bash

# ========================================
# Setup Environment Files
# ========================================
# This script copies all .env.example files to .env
# for easy local development setup

echo "🔧 Setting up environment files..."
echo ""

# Auth Service
if [ ! -f "services/auth-service/.env" ]; then
    cp services/auth-service/.env.example services/auth-service/.env
    echo "✅ Created services/auth-service/.env"
else
    echo "⏭️  services/auth-service/.env already exists"
fi

# Search Service
if [ ! -f "services/search-service/.env" ]; then
    cp services/search-service/.env.example services/search-service/.env
    echo "✅ Created services/search-service/.env"
else
    echo "⏭️  services/search-service/.env already exists"
fi

# Booking Service
if [ ! -f "services/booking-service/.env" ]; then
    cp services/booking-service/.env.example services/booking-service/.env
    echo "✅ Created services/booking-service/.env"
else
    echo "⏭️  services/booking-service/.env already exists"
fi

# Payment Service
if [ ! -f "services/payment-service/.env" ]; then
    cp services/payment-service/.env.example services/payment-service/.env
    echo "✅ Created services/payment-service/.env"
else
    echo "⏭️  services/payment-service/.env already exists"
fi

# Notification Service
if [ ! -f "services/notification-service/.env" ]; then
    cp services/notification-service/.env.example services/notification-service/.env
    echo "✅ Created services/notification-service/.env"
else
    echo "⏭️  services/notification-service/.env already exists"
fi

# Gateway
if [ ! -f "gateway/.env" ]; then
    cp gateway/.env.example gateway/.env
    echo "✅ Created gateway/.env"
else
    echo "⏭️  gateway/.env already exists"
fi

echo ""
echo "✅ Environment files setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Review and modify .env files if needed"
echo "   2. Run services manually from CLI (see RUN_SERVICES_GUIDE.md)"
echo ""

