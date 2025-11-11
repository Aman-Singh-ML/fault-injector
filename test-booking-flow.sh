#!/bin/bash

# Test script for hotel reservation system
GATEWAY_URL="http://192.168.49.2"
echo "🧪 Testing Hotel Reservation System at $GATEWAY_URL"
echo "=================================================="

# Test 1: Health check
echo ""
echo "1️⃣ Testing Gateway Health..."
kubectl exec -n hotel-reserve-dummy deployment/frontend -- wget -q -O- http://gateway:9000/health 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Gateway is healthy"
else
    echo "❌ Gateway health check failed"
fi

# Test 2: Search hotels
echo ""
echo "2️⃣ Testing Hotel Search..."
kubectl exec -n hotel-reserve-dummy deployment/frontend -- wget -q -O- http://gateway:9000/api/search/hotels 2>/dev/null | head -c 200
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Hotel search is working"
else
    echo "❌ Hotel search failed"
fi

# Test 3: Check booking service
echo ""
echo "3️⃣ Testing Booking Service Health..."
kubectl exec -n hotel-reserve-dummy deployment/frontend -- wget -q -O- http://booking-service:8000/health 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Booking service is healthy"
else
    echo "❌ Booking service health check failed"
fi

# Test 4: Check auth service
echo ""
echo "4️⃣ Testing Auth Service Health..."
kubectl exec -n hotel-reserve-dummy deployment/frontend -- wget -q -O- http://auth-service:8001/health 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Auth service is healthy"
else
    echo "❌ Auth service health check failed"
fi

echo ""
echo "=================================================="
echo "🌐 Access the application at: $GATEWAY_URL"
echo "=================================================="

