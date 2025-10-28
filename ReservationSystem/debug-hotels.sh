#!/bin/bash

# Comprehensive debugging script for hotel availability issue

echo "🔍 DEBUGGING HOTEL AVAILABILITY ISSUE"
echo "======================================"
echo ""

# Test 1: Check if MongoDB has data
echo "📊 Test 1: Checking MongoDB data..."
docker exec -it mongodb mongosh --eval "
db = db.getSiblingDB('hotel_db');
db.hotels.find({}, {name: 1, rooms_available: 1, total_rooms: 1}).pretty();
" 2>/dev/null || echo "❌ MongoDB check failed"
echo ""

# Test 2: Check Search Service directly
echo "📡 Test 2: Checking Search Service (port 8081)..."
curl -s "http://localhost:8081/search/hotels" 2>&1 | jq . 2>/dev/null || curl -s "http://localhost:8081/search/hotels" 2>&1
echo ""

# Test 3: Check Gateway
echo "🚪 Test 3: Checking Gateway (port 9000)..."
curl -s "http://localhost:9000/search/hotels" 2>&1 | jq . 2>/dev/null || curl -s "http://localhost:9000/search/hotels" 2>&1
echo ""

# Test 4: Check Frontend API Proxy
echo "🌐 Test 4: Checking Frontend API Proxy (port 3000)..."
curl -s "http://localhost:3000/api/search/hotels" 2>&1 | jq . 2>/dev/null || curl -s "http://localhost:3000/api/search/hotels" 2>&1
echo ""

# Test 5: Check Redis cache
echo "💾 Test 5: Checking Redis cache..."
redis-cli -p 6381 GET "search:hotels:all" 2>/dev/null | jq . 2>/dev/null || echo "❌ Redis check failed"
echo ""

# Test 6: Check service health
echo "🏥 Test 6: Checking service health..."
echo "Search Service:"
curl -s "http://localhost:8081/health" 2>&1 | jq . 2>/dev/null || curl -s "http://localhost:8081/health" 2>&1
echo ""
echo "Gateway:"
curl -s "http://localhost:9000/health" 2>&1 | jq . 2>/dev/null || curl -s "http://localhost:9000/health" 2>&1
echo ""

# Test 7: Check logs for errors
echo "📋 Test 7: Recent errors in logs..."
echo "Search Service errors:"
grep -i "error\|fail" /Users/amritakumari/Documents/fault-injector/ReservationSystem/logs/search-service.log | tail -5
echo ""
echo "Gateway errors:"
grep -i "error\|fail" /Users/amritakumari/Documents/fault-injector/ReservationSystem/logs/gateway.log | tail -5
echo ""

echo "✅ Debugging complete!"

