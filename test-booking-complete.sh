#!/bin/bash

echo "🧪 Testing Complete Booking Flow..."
echo ""

GATEWAY_URL="http://127.0.0.1:61707"

# Step 1: Register a new user
echo "1️⃣ Registering new user..."
REGISTER_RESPONSE=$(curl -s ${GATEWAY_URL}/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "email": "testuser'$(date +%s)'@example.com",
    "password": "Test123!",
    "phone": "+1234567890"
  }')

echo "Registration response: $REGISTER_RESPONSE"
TOKEN=$(echo $REGISTER_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || echo "")

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to register user"
    exit 1
fi

echo "✅ User registered successfully"
echo "Token: ${TOKEN:0:50}..."
echo ""

# Step 2: Get hotels
echo "2️⃣ Fetching hotels..."
HOTELS=$(curl -s ${GATEWAY_URL}/search/hotels)
echo "Hotels found: $(echo $HOTELS | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")"
echo ""

# Step 3: Create a booking
echo "3️⃣ Creating booking..."
BOOKING_RESPONSE=$(curl -s ${GATEWAY_URL}/bookings/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "hotelId": "1",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-12-01",
    "checkOutDate": "2025-12-05",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500.00
  }')

echo "Booking response: $BOOKING_RESPONSE"
echo ""

# Step 4: Wait for Kafka to process the booking
echo "4️⃣ Waiting for booking to be processed (10 seconds)..."
sleep 10
echo ""

# Step 5: Get bookings
echo "5️⃣ Fetching user bookings..."
BOOKINGS=$(curl -s ${GATEWAY_URL}/booking/bookings \
  -H "Authorization: Bearer $TOKEN")

echo "Bookings: $BOOKINGS"
echo ""

if [ "$BOOKINGS" = "[]" ]; then
    echo "⚠️  No bookings found yet (Kafka might still be processing)"
else
    echo "✅ Booking retrieved successfully!"
    echo "Number of bookings: $(echo $BOOKINGS | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")"
fi

