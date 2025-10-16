# 🧪 Copy-Paste Test Commands

**All commands are ready to copy and paste into your terminal!**

---

## 🔐 **1. TEST LOGIN (All Users)**

### Test 1: Login as Customer (a@a.com)
```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"admin123"}' | python3 -m json.tool
```

**Expected Output**:
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 3,
        "email": "a@a.com",
        "firstName": "A",
        "lastName": "User",
        "role": "CUSTOMER"
    }
}
```

### Test 2: Login as Admin
```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hotel.com","password":"admin123"}' | python3 -m json.tool
```

### Test 3: Login with Wrong Password (Should Fail)
```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"wrongpassword"}' | python3 -m json.tool
```

**Expected Output**:
```json
{
    "error": "Invalid credentials"
}
```

---

## 🏨 **2. TEST HOTEL SEARCH**

### Get Token First:
```bash
TOKEN=$(curl -s -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")

echo "Token: $TOKEN"
```

### Test 1: Search All Hotels
```bash
curl -X GET "http://localhost:9000/search/hotels" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -40
```

### Test 2: Search with City Filter
```bash
curl -X GET "http://localhost:9000/search/hotels?city=New%20York" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

---

## 📅 **3. TEST BOOKING**

### Test 1: Create a Booking
```bash
curl -X POST http://localhost:9000/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "3",
    "hotelId": "hotel_001",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-10-20",
    "checkOutDate": "2025-10-22",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500
  }' | python3 -m json.tool
```

### Test 2: Get My Bookings
```bash
curl -X GET http://localhost:9000/booking/bookings \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### Test 3: Check Availability (with Redis Cache)
```bash
curl -X GET "http://localhost:9000/booking/availability/check?hotel_id=hotel_001&check_in=2025-10-25&check_out=2025-10-27&rooms=1" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### Test 4: Get Cache Statistics
```bash
curl -X GET "http://localhost:9000/booking/availability/stats" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

---

## 💳 **4. TEST PAYMENT**

### Test 1: Initiate Payment (Replace BOOKING_ID with actual ID)
```bash
BOOKING_ID=2  # Replace with your booking ID

curl -X POST http://localhost:9000/payment/initiate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"bookingId\":$BOOKING_ID,\"userId\":3,\"amount\":500}" | python3 -m json.tool
```

---

## 🔔 **5. TEST NOTIFICATIONS**

### Test 1: Get My Notifications
```bash
curl -s http://localhost:8083/notifications/3 | python3 -m json.tool
```

### Test 2: Get Notification Count
```bash
curl -s http://localhost:8083/notifications/3 | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'Total: {len(data[\"notifications\"])}, Unread: {data[\"unreadCount\"]}')"
```

---

## 👨‍💼 **6. TEST ADMIN PANEL**

### Get Admin Token First:
```bash
ADMIN_TOKEN=$(curl -s -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hotel.com","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")

echo "Admin Token: $ADMIN_TOKEN"
```

### Test 1: Get Analytics
```bash
curl -s http://localhost:9000/auth/admin/analytics \
  -H "Authorization: Bearer $ADMIN_TOKEN" | python3 -m json.tool
```

### Test 2: Get All Hotels
```bash
curl -s http://localhost:9000/admin/hotels \
  -H "Authorization: Bearer $ADMIN_TOKEN" | python3 -m json.tool
```

### Test 3: Get All Bookings
```bash
curl -s http://localhost:9000/admin/bookings \
  -H "Authorization: Bearer $ADMIN_TOKEN" | python3 -m json.tool
```

---

## 🗄️ **7. TEST DATABASE ISOLATION**

### Test 1: Check Auth Database
```bash
docker exec hotel-postgres-auth psql -U auth_user -d auth_db \
  -c "SELECT id, email, role FROM users;"
```

### Test 2: Check Booking Database
```bash
docker exec hotel-postgres-booking psql -U booking_user -d booking_db \
  -c "SELECT id, user_id, hotel_name, status FROM bookings;"
```

### Test 3: Check Payment Database
```bash
docker exec hotel-postgres-payment psql -U payment_user -d payment_db \
  -c "SELECT id, booking_id, amount, status FROM payments LIMIT 5;"
```

---

## 🚪 **8. TEST GATEWAY FEATURES**

### Test 1: Health Check
```bash
curl -s http://localhost:9000/health | python3 -m json.tool
```

### Test 2: Circuit Breaker Status
```bash
curl -s http://localhost:9000/health | \
  python3 -c "import sys, json; data = json.load(sys.stdin); cb = data.get('circuitBreakers', {}); print('Circuit Breakers:'); [print(f'  {k}: {v.get(\"state\", \"N/A\")}') for k, v in cb.items()]"
```

### Test 3: Rate Limiting (Try 10 failed logins)
```bash
echo "Testing rate limiting (5 req/15min for auth):"
for i in {1..10}; do
  echo "Request $i:"
  curl -s -X POST http://localhost:9000/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrong"}' | \
    python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('error', 'Success'))"
  sleep 0.5
done
```

---

## 🔍 **9. TEST INFRASTRUCTURE**

### Test 1: Check All Docker Containers
```bash
docker-compose -f docker-compose-infrastructure.yml ps
```

### Test 2: Check Database Counts
```bash
echo "=== Database Counts ===" && \
echo "Auth DB:" && docker exec hotel-postgres-auth psql -U auth_user -d auth_db -t -c "SELECT COUNT(*) FROM users;" && \
echo "Booking DB:" && docker exec hotel-postgres-booking psql -U booking_user -d booking_db -t -c "SELECT COUNT(*) FROM bookings;" && \
echo "Payment DB:" && docker exec hotel-postgres-payment psql -U payment_user -d payment_db -t -c "SELECT COUNT(*) FROM payments;"
```

### Test 3: Check Redis
```bash
docker exec hotel-redis redis-cli ping
```

### Test 4: Check Kafka Topics
```bash
docker exec hotel-kafka kafka-topics --list --bootstrap-server localhost:9092
```

### Test 5: Check RabbitMQ
```bash
echo "RabbitMQ Management UI: http://localhost:15672"
echo "Username: admin"
echo "Password: admin"
```

---

## 🎯 **10. COMPLETE WORKFLOW TEST**

### Run Full Workflow (Login → Search → Book → Check Notification):
```bash
echo "=== COMPLETE WORKFLOW TEST ===" && \
echo "" && \
echo "Step 1: Login" && \
TOKEN=$(curl -s -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"admin123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])") && \
echo "✅ Logged in" && \
echo "" && \
echo "Step 2: Search Hotels" && \
HOTELS=$(curl -s -X GET "http://localhost:9000/search/hotels" \
  -H "Authorization: Bearer $TOKEN" | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(len(data))") && \
echo "✅ Found $HOTELS hotels" && \
echo "" && \
echo "Step 3: Create Booking" && \
BOOKING=$(curl -s -X POST http://localhost:9000/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "3",
    "hotelId": "hotel_001",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-11-01",
    "checkOutDate": "2025-11-03",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500
  }') && \
BOOKING_ID=$(echo $BOOKING | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])") && \
echo "✅ Booking created: $BOOKING_ID" && \
echo "" && \
echo "Step 4: Check Notifications (wait 2 seconds for Kafka)" && \
sleep 2 && \
NOTIFS=$(curl -s http://localhost:8083/notifications/3 | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'Total: {len(data[\"notifications\"])}, Unread: {data[\"unreadCount\"]}')") && \
echo "✅ Notifications: $NOTIFS" && \
echo "" && \
echo "=== WORKFLOW COMPLETE ==="
```

---

## 📊 **11. PERFORMANCE TEST**

### Test Redis Cache Performance:
```bash
echo "Testing availability cache performance..." && \
echo "" && \
echo "First request (cache miss):" && \
time curl -s -X GET "http://localhost:9000/booking/availability/check?hotel_id=hotel_001&check_in=2025-12-01&check_out=2025-12-05&rooms=1" \
  -H "Authorization: Bearer $TOKEN" > /dev/null && \
echo "" && \
echo "Second request (cache hit):" && \
time curl -s -X GET "http://localhost:9000/booking/availability/check?hotel_id=hotel_001&check_in=2025-12-01&check_out=2025-12-05&rooms=1" \
  -H "Authorization: Bearer $TOKEN" > /dev/null
```

---

## 🔧 **12. TROUBLESHOOTING COMMANDS**

### If Login Fails - Reset Passwords:
```bash
docker exec hotel-postgres-auth psql -U auth_user -d auth_db \
  -c "UPDATE users SET password = '\$2b\$10\$rpUHEk7gb9rAUYjdUHemm.m8HEgalNTOOEen.wfb9hwH2ts.0REYu';"
```

### Check Service Logs:
```bash
# Gateway logs
cd gateway && npm start

# Booking service logs
cd services/booking-service && python3 -m app.main

# Check if services are running
lsof -i:9000  # Gateway
lsof -i:8000  # Booking
lsof -i:8081  # Search
lsof -i:8082  # Payment
lsof -i:8083  # Notification
```

### Restart Infrastructure:
```bash
docker-compose -f docker-compose-infrastructure.yml restart
```

---

## ✅ **EXPECTED RESULTS**

All tests should return:
- ✅ Login: Token generated
- ✅ Search: 4 hotels found
- ✅ Booking: Booking created with ID
- ✅ Availability: Cache working (faster on 2nd request)
- ✅ Notifications: Events received from Kafka
- ✅ Admin: All data visible
- ✅ Databases: 3 separate instances running
- ✅ Gateway: Circuit breakers and rate limiting active

---

**All commands tested and verified working! 🎉**

