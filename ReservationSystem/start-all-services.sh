#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 STARTING HOTEL RESERVATION SYSTEM - ALL SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if infrastructure is running
echo "📊 Checking infrastructure..."
if ! docker ps | grep -q hotel-postgres-auth; then
    echo "⚠️  Infrastructure not running. Starting docker-compose..."
    docker-compose -f docker-compose-infrastructure.yml up -d
    echo "⏳ Waiting for infrastructure to be ready..."
    sleep 10
else
    echo "✅ Infrastructure already running"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 STARTING MICROSERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to check if port is in use
check_port() {
    lsof -i:$1 > /dev/null 2>&1
    return $?
}

# Start API Gateway
echo "1️⃣  Starting API Gateway (port 9000)..."
if check_port 9000; then
    echo "   ⚠️  Port 9000 already in use, skipping..."
else
    cd gateway
    npm start > ../logs/gateway.log 2>&1 &
    echo "   ✅ API Gateway started (PID: $!)"
    cd ..
fi

sleep 2

# Start Search Service
echo ""
echo "2️⃣  Starting Search Service (port 8081)..."
if check_port 8081; then
    echo "   ⚠️  Port 8081 already in use, skipping..."
else
    cd services/search-service
    PORT=8081 go run cmd/main.go > ../../logs/search.log 2>&1 &
    echo "   ✅ Search Service started (PID: $!)"
    cd ../..
fi

sleep 2

# Start Booking Service
echo ""
echo "3️⃣  Starting Booking Service (port 8000)..."
if check_port 8000; then
    echo "   ⚠️  Port 8000 already in use, skipping..."
else
    cd services/booking-service
    python3 -m app.main > ../../logs/booking.log 2>&1 &
    echo "   ✅ Booking Service started (PID: $!)"
    cd ../..
fi

sleep 2

# Start Payment Service
echo ""
echo "4️⃣  Starting Payment Service (port 8082)..."
if check_port 8082; then
    echo "   ⚠️  Port 8082 already in use, skipping..."
else
    cd services/payment-service
    go run cmd/main.go > ../../logs/payment.log 2>&1 &
    echo "   ✅ Payment Service started (PID: $!)"
    cd ../..
fi

sleep 2

# Start Notification Service
echo ""
echo "5️⃣  Starting Notification Service (port 8083)..."
if check_port 8083; then
    echo "   ⚠️  Port 8083 already in use, skipping..."
else
    cd services/notification-service
    python3 -m app.main > ../../logs/notification.log 2>&1 &
    echo "   ✅ Notification Service started (PID: $!)"
    cd ../..
fi

sleep 2

# Start Frontend
echo ""
echo "6️⃣  Starting Frontend (port 3000)..."
if check_port 3000; then
    echo "   ⚠️  Port 3000 already in use, skipping..."
else
    cd frontend
    npm run dev > ../logs/frontend.log 2>&1 &
    echo "   ✅ Frontend started (PID: $!)"
    cd ..
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ WAITING FOR SERVICES TO BE READY..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sleep 5

# Check service health
echo "🏥 Checking service health..."
echo ""

# Check Gateway
if curl -s http://localhost:9000/health > /dev/null 2>&1; then
    echo "✅ API Gateway (9000) - HEALTHY"
else
    echo "❌ API Gateway (9000) - NOT RESPONDING"
fi

# Check Search
if curl -s http://localhost:8081/health > /dev/null 2>&1; then
    echo "✅ Search Service (8081) - HEALTHY"
else
    echo "❌ Search Service (8081) - NOT RESPONDING"
fi

# Check Booking
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Booking Service (8000) - HEALTHY"
else
    echo "❌ Booking Service (8000) - NOT RESPONDING"
fi

# Check Payment
if curl -s http://localhost:8082/health > /dev/null 2>&1; then
    echo "✅ Payment Service (8082) - HEALTHY"
else
    echo "❌ Payment Service (8082) - NOT RESPONDING"
fi

# Check Notification
if curl -s http://localhost:8083/health > /dev/null 2>&1; then
    echo "✅ Notification Service (8083) - HEALTHY"
else
    echo "❌ Notification Service (8083) - NOT RESPONDING"
fi

# Check Frontend
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend (3000) - HEALTHY"
else
    echo "❌ Frontend (3000) - NOT RESPONDING"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 ALL SERVICES STARTED!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Access Points:"
echo "   Frontend:     http://localhost:3000"
echo "   API Gateway:  http://localhost:9000"
echo "   API Docs:     http://localhost:9000/health"
echo ""
echo "🔐 Login Credentials:"
echo "   Customer:  a@a.com / 123456"
echo "   Admin:     admin@hotel.com / admin123"
echo ""
echo "📝 Logs are available in the 'logs' directory"
echo ""
echo "🛑 To stop all services, run: ./stop-all-services.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

