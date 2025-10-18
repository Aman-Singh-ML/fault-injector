#!/bin/bash

# Script to generate test traffic for business and Kafka metrics

set -e

GATEWAY_URL="${GATEWAY_URL:-http://localhost:9000}"

echo "🚀 Generating test traffic to populate metrics..."
echo "Gateway URL: $GATEWAY_URL"
echo ""

# Function to make API calls with error handling
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local headers=$4
    
    if [ -n "$data" ]; then
        if [ -n "$headers" ]; then
            curl -s -X $method "$GATEWAY_URL$endpoint" \
                -H "Content-Type: application/json" \
                -H "$headers" \
                -d "$data"
        else
            curl -s -X $method "$GATEWAY_URL$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data"
        fi
    else
        curl -s -X $method "$GATEWAY_URL$endpoint"
    fi
}

# 1. Register a user
echo "1️⃣  Registering test user..."
REGISTER_RESPONSE=$(api_call POST "/auth/register" '{
    "email": "testuser@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
}')
echo "   ✅ User registered"
echo ""

# 2. Login to get token
echo "2️⃣  Logging in..."
LOGIN_RESPONSE=$(api_call POST "/auth/login" '{
    "email": "testuser@example.com",
    "password": "password123"
}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "   ❌ Failed to get token. Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "   ✅ Login successful"
echo "   Token: ${TOKEN:0:20}..."
echo ""

# 3. Search for hotels
echo "3️⃣  Searching for hotels..."
SEARCH_RESPONSE=$(api_call GET "/search/hotels?city=NewYork&checkIn=2025-11-01&checkOut=2025-11-05")
echo "   ✅ Hotel search completed"
echo ""

# 4. Create a booking
echo "4️⃣  Creating a booking..."
BOOKING_RESPONSE=$(api_call POST "/booking/bookings" '{
    "userId": "1",
    "hotelId": "hotel-123",
    "hotelName": "Test Hotel New York",
    "checkInDate": "2025-11-01T00:00:00Z",
    "checkOutDate": "2025-11-05T00:00:00Z",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500.00
}' "Authorization: Bearer $TOKEN")

BOOKING_ID=$(echo $BOOKING_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -z "$BOOKING_ID" ]; then
    echo "   ⚠️  Booking creation may have failed. Response: $BOOKING_RESPONSE"
else
    echo "   ✅ Booking created: ID=$BOOKING_ID"
fi
echo ""

# 5. Initiate payment (if booking was created)
if [ -n "$BOOKING_ID" ]; then
    echo "5️⃣  Initiating payment..."
    PAYMENT_RESPONSE=$(api_call POST "/payment/initiate" '{
        "bookingId": "'$BOOKING_ID'",
        "userId": "1",
        "amount": 500.00
    }' "Authorization: Bearer $TOKEN")
    
    PAYMENT_ID=$(echo $PAYMENT_RESPONSE | grep -o '"paymentId":[0-9]*' | cut -d':' -f2)
    OTP=$(echo $PAYMENT_RESPONSE | grep -o '"otp":"[^"]*' | cut -d'"' -f4)
    
    if [ -n "$PAYMENT_ID" ]; then
        echo "   ✅ Payment initiated: ID=$PAYMENT_ID, OTP=$OTP"
        echo ""
        
        # 6. Verify payment
        echo "6️⃣  Verifying payment..."
        VERIFY_RESPONSE=$(api_call POST "/payment/verify" '{
            "paymentId": '$PAYMENT_ID',
            "otp": "'$OTP'"
        }' "Authorization: Bearer $TOKEN")
        echo "   ✅ Payment verified"
    else
        echo "   ⚠️  Payment initiation may have failed. Response: $PAYMENT_RESPONSE"
    fi
else
    echo "5️⃣  Skipping payment (no booking ID)"
fi

echo ""
echo "✅ Test traffic generation complete!"
echo ""
echo "📊 Check metrics:"
echo "   Gateway metrics:       curl $GATEWAY_URL/metrics | grep gateway_"
echo "   Booking service:       kubectl port-forward -n hotel-reservation svc/booking-service 8000:8000"
echo "                          curl http://localhost:8000/metrics | grep kafka"
echo "   Notification service:  kubectl port-forward -n hotel-reservation svc/notification-service 8083:8083"
echo "                          curl http://localhost:8083/metrics | grep kafka"
echo ""
echo "📈 View dashboards:"
echo "   kubectl port-forward -n hotel-reservation svc/grafana 3000:3000"
echo "   Open http://localhost:3000 (admin/admin123)"
echo "   - Business Metrics Dashboard"
echo "   - Kafka Monitoring Dashboard"

