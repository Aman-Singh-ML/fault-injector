#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 TESTING KUBERNETES DEPLOYMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get Gateway NodePort
GATEWAY_PORT=$(kubectl get svc gateway -n hotel-reservation -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

if [ -z "$GATEWAY_PORT" ]; then
    echo "❌ Gateway service not found. Please deploy first with ./deploy-to-kubernetes.sh"
    exit 1
fi

GATEWAY_URL="http://localhost:$GATEWAY_PORT"

echo "🌐 Testing Gateway at: $GATEWAY_URL"
echo ""

# Test 1: Health Check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TEST 1: Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

HEALTH_RESPONSE=$(curl -s $GATEWAY_URL/health)
if [ $? -eq 0 ]; then
    echo "✅ Gateway is responding"
    echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"
else
    echo "❌ Gateway is not responding"
    echo "   Trying port-forward..."
    kubectl port-forward svc/gateway 9000:9000 -n hotel-reservation &
    PF_PID=$!
    sleep 3
    GATEWAY_URL="http://localhost:9000"
    echo "   Retrying with port-forward..."
    curl -s $GATEWAY_URL/health | python3 -m json.tool 2>/dev/null
fi

echo ""

# Test 2: Login
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TEST 2: Login"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Logging in as a@a.com..."
LOGIN_RESPONSE=$(curl -s -X POST $GATEWAY_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"123456"}')

TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('token', ''))" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    echo "✅ Login successful"
    echo "   Token: ${TOKEN:0:50}..."
else
    echo "❌ Login failed"
    echo "   Response: $LOGIN_RESPONSE"
    if [ -n "$PF_PID" ]; then
        kill $PF_PID 2>/dev/null
    fi
    exit 1
fi

echo ""

# Test 3: Search Hotels
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TEST 3: Search Hotels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SEARCH_RESPONSE=$(curl -s -X GET "$GATEWAY_URL/search/hotels" \
  -H "Authorization: Bearer $TOKEN")

HOTEL_COUNT=$(echo $SEARCH_RESPONSE | python3 -c "import sys, json; data = json.load(sys.stdin); print(len(data))" 2>/dev/null)

if [ -n "$HOTEL_COUNT" ] && [ "$HOTEL_COUNT" -gt 0 ]; then
    echo "✅ Search successful"
    echo "   Found $HOTEL_COUNT hotels"
else
    echo "⚠️  Search returned no results or failed"
    echo "   Response: $(echo $SEARCH_RESPONSE | head -c 200)"
fi

echo ""

# Test 4: Create Booking
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TEST 4: Create Booking"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BOOKING_RESPONSE=$(curl -s -X POST $GATEWAY_URL/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "3",
    "hotelId": "hotel_001",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-12-20",
    "checkOutDate": "2025-12-22",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500
  }')

BOOKING_ID=$(echo $BOOKING_RESPONSE | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('id', ''))" 2>/dev/null)

if [ -n "$BOOKING_ID" ]; then
    echo "✅ Booking created successfully"
    echo "   Booking ID: $BOOKING_ID"
else
    echo "⚠️  Booking creation failed or returned unexpected response"
    echo "   Response: $(echo $BOOKING_RESPONSE | head -c 200)"
fi

echo ""

# Test 5: Initiate Payment
if [ -n "$BOOKING_ID" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ TEST 5: Initiate Payment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    PAYMENT_RESPONSE=$(curl -s -X POST $GATEWAY_URL/payment/initiate \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"bookingId\":$BOOKING_ID,\"userId\":3,\"amount\":500}")

    PAYMENT_ID=$(echo $PAYMENT_RESPONSE | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('paymentId', ''))" 2>/dev/null)
    OTP=$(echo $PAYMENT_RESPONSE | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('otp', ''))" 2>/dev/null)

    if [ -n "$PAYMENT_ID" ] && [ -n "$OTP" ]; then
        echo "✅ Payment initiated successfully"
        echo "   Payment ID: $PAYMENT_ID"
        echo "   OTP: $OTP"
        
        # Test 6: Verify OTP
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ TEST 6: Verify OTP"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        VERIFY_RESPONSE=$(curl -s -X POST $GATEWAY_URL/payment/verify-otp \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"paymentId\":\"$PAYMENT_ID\",\"otp\":\"$OTP\"}")

        PAYMENT_STATUS=$(echo $VERIFY_RESPONSE | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('status', ''))" 2>/dev/null)

        if [ "$PAYMENT_STATUS" = "COMPLETED" ]; then
            echo "✅ OTP verification successful"
            echo "   Payment Status: $PAYMENT_STATUS"
            echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null
        else
            echo "⚠️  OTP verification failed or returned unexpected response"
            echo "   Response: $(echo $VERIFY_RESPONSE | head -c 200)"
        fi
    else
        echo "⚠️  Payment initiation failed or returned unexpected response"
        echo "   Response: $(echo $PAYMENT_RESPONSE | head -c 200)"
    fi
fi

echo ""

# Test 7: Check Pods Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TEST 7: Kubernetes Resources Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📦 Pods:"
kubectl get pods -n hotel-reservation

echo ""
echo "🌐 Services:"
kubectl get svc -n hotel-reservation

echo ""

# Cleanup port-forward if it was started
if [ -n "$PF_PID" ]; then
    kill $PF_PID 2>/dev/null
    echo "🧹 Cleaned up port-forward process"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 TESTING COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "   Gateway URL: $GATEWAY_URL"
echo "   Login: ✅"
echo "   Search: $([ -n "$HOTEL_COUNT" ] && echo "✅" || echo "⚠️")"
echo "   Booking: $([ -n "$BOOKING_ID" ] && echo "✅" || echo "⚠️")"
echo "   Payment: $([ "$PAYMENT_STATUS" = "COMPLETED" ] && echo "✅" || echo "⚠️")"
echo ""

