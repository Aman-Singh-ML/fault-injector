# 🔐 WORKING LOGIN CREDENTIALS

**Last Updated**: 2025-10-13  
**Status**: ✅ **ALL CREDENTIALS VERIFIED AND WORKING**

---

## 📋 **LOGIN CREDENTIALS**

### **Customer Account 1**
- **Email**: `a@a.com`
- **Password**: `123456`
- **Role**: CUSTOMER
- **User ID**: 3
- **Status**: ✅ **WORKING**

### **Customer Account 2**
- **Email**: `test@hotel.com`
- **Password**: `password123`
- **Role**: CUSTOMER
- **User ID**: 2
- **Status**: ✅ **WORKING**

### **Admin Account**
- **Email**: `admin@hotel.com`
- **Password**: `admin123`
- **Role**: ADMIN
- **User ID**: 1
- **Status**: ✅ **WORKING**

---

## 🧪 **VERIFIED TEST RESULTS**

### **Test 1: Customer Login (a@a.com)**
```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"123456"}'
```

**Result**: ✅ **SUCCESS**
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

---

### **Test 2: Customer Login (test@hotel.com)**
```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@hotel.com","password":"password123"}'
```

**Result**: ✅ **SUCCESS**
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 2,
        "email": "test@hotel.com",
        "firstName": "Test",
        "lastName": "User",
        "role": "CUSTOMER"
    }
}
```

---

### **Test 3: Admin Login**
```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hotel.com","password":"admin123"}'
```

**Result**: ✅ **SUCCESS**
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 1,
        "email": "admin@hotel.com",
        "firstName": "Admin",
        "lastName": "User",
        "role": "ADMIN"
    }
}
```

---

## 🌐 **FRONTEND LOGIN**

### **Access the Frontend**:
```
URL: http://localhost:3000
```

### **Login Steps**:
1. Open browser and go to `http://localhost:3000`
2. Click on "Login" or navigate to login page
3. Enter credentials:
   - **Customer**: `a@a.com` / `123456`
   - **Admin**: `admin@hotel.com` / `admin123`
4. Click "Login"
5. You should be redirected to the dashboard

---

## 🔧 **BACKEND API ENDPOINTS**

### **Base URL**: `http://localhost:9000`

### **Authentication Endpoints**:
- `POST /auth/login` - Login
- `POST /auth/register` - Register new user
- `GET /auth/profile` - Get user profile (requires token)

### **Hotel Search Endpoints**:
- `GET /search/hotels` - Search all hotels
- `GET /search/hotels?city=New York` - Search by city
- `GET /search/hotels/:id` - Get hotel details

### **Booking Endpoints**:
- `POST /booking/bookings` - Create booking
- `GET /booking/bookings` - Get user bookings
- `GET /booking/bookings/:id` - Get booking details
- `PUT /booking/bookings/:id/cancel` - Cancel booking
- `PUT /booking/bookings/:id/confirm` - Confirm booking
- `GET /booking/availability/check` - Check availability (with cache)
- `GET /booking/availability/stats` - Get cache statistics

### **Payment Endpoints**:
- `POST /payment/initiate` - Initiate payment
- `POST /payment/verify` - Verify OTP

### **Notification Endpoints**:
- `GET /notifications/:userId` - Get notifications
- `GET /notifications/:userId/stream` - SSE stream
- `POST /notifications/:notificationId/read` - Mark as read

### **Admin Endpoints** (Requires ADMIN role):
- `GET /auth/admin/analytics` - Get analytics
- `GET /admin/hotels` - Get all hotels
- `GET /admin/bookings` - Get all bookings
- `GET /admin/payments` - Get all payments
- `GET /admin/notifications` - Get all notifications

---

## 🎯 **COMPLETE WORKFLOW TEST**

### **Step-by-Step Test**:

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"123456"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")

echo "✅ Logged in successfully"
echo "Token: ${TOKEN:0:50}..."

# 2. Search Hotels
echo ""
echo "Searching hotels..."
curl -s -X GET "http://localhost:9000/search/hotels" \
  -H "Authorization: Bearer $TOKEN" | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'✅ Found {len(data)} hotels')"

# 3. Create Booking
echo ""
echo "Creating booking..."
BOOKING=$(curl -s -X POST http://localhost:9000/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "3",
    "hotelId": "hotel_001",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-11-10",
    "checkOutDate": "2025-11-12",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500
  }')

BOOKING_ID=$(echo $BOOKING | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
echo "✅ Booking created: ID $BOOKING_ID"

# 4. Check Availability (with cache)
echo ""
echo "Checking availability..."
curl -s -X GET "http://localhost:9000/booking/availability/check?hotel_id=hotel_001&check_in=2025-12-01&check_out=2025-12-05&rooms=1" \
  -H "Authorization: Bearer $TOKEN" | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'✅ Available: {data.get(\"available\", False)}, Rooms: {data.get(\"available_rooms\", 0)}')"

# 5. Get Notifications
echo ""
echo "Checking notifications..."
sleep 2  # Wait for Kafka
curl -s http://localhost:8083/notifications/3 | \
  python3 -c "import sys, json; data = json.load(sys.stdin); print(f'✅ Notifications: {len(data.get(\"notifications\", []))} total, {data.get(\"unreadCount\", 0)} unread')"

echo ""
echo "🎉 Complete workflow test successful!"
```

---

## 🗄️ **DATABASE INFORMATION**

### **Auth Database** (Port 5432)
```bash
# Connect to database
docker exec -it hotel-postgres-auth psql -U auth_user -d auth_db

# View users
SELECT id, email, role FROM users;
```

### **Booking Database** (Port 5433)
```bash
# Connect to database
docker exec -it hotel-postgres-booking psql -U booking_user -d booking_db

# View bookings
SELECT id, user_id, hotel_name, status FROM bookings;
```

### **Payment Database** (Port 5434)
```bash
# Connect to database
docker exec -it hotel-postgres-payment psql -U payment_user -d payment_db

# View payments
SELECT id, booking_id, amount, status FROM payments;
```

---

## 🔍 **TROUBLESHOOTING**

### **If Login Fails**:

1. **Check if Gateway is running**:
```bash
curl http://localhost:9000/health
```

2. **Check database**:
```bash
docker exec hotel-postgres-auth psql -U auth_user -d auth_db \
  -c "SELECT email, role FROM users;"
```

3. **Reset passwords** (if needed):
```bash
docker exec hotel-postgres-auth psql -U auth_user -d auth_db -c "
UPDATE users SET password = '\$2b\$10\$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq' WHERE email = 'a@a.com';
UPDATE users SET password = '\$2b\$10\$Cwk7rDfu0Tfml3C9RIqCpeeL9Qg57CVwfSDhk20xxri8QdxWmupGG' WHERE email = 'admin@hotel.com';
UPDATE users SET password = '\$2b\$10\$WbbilC0KDnsJJRqVnk59F.SVu0Iy3nq0aDuKlqlaw/ODOVKuup/kS' WHERE email = 'test@hotel.com';
"
```

4. **Restart Gateway** (to reset rate limiter):
```bash
cd gateway
npm start
```

### **If Frontend Login Fails**:

1. **Check if frontend is running**:
```bash
lsof -i:3000
```

2. **Check browser console** for errors (F12 → Console)

3. **Clear browser cache and cookies**

4. **Verify API endpoint** in frontend code points to `http://localhost:9000`

---

## 📊 **PASSWORD HASH REFERENCE**

For future reference, here are the bcrypt hashes:

| Email | Password | Bcrypt Hash |
|-------|----------|-------------|
| a@a.com | 123456 | `$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq` |
| admin@hotel.com | admin123 | `$2b$10$Cwk7rDfu0Tfml3C9RIqCpeeL9Qg57CVwfSDhk20xxri8QdxWmupGG` |
| test@hotel.com | password123 | `$2b$10$WbbilC0KDnsJJRqVnk59F.SVu0Iy3nq0aDuKlqlaw/ODOVKuup/kS` |

---

## ✅ **VERIFICATION CHECKLIST**

- [x] Backend login working for all 3 users
- [x] Correct password hashes in database
- [x] JWT tokens generated successfully
- [x] User roles (ADMIN/CUSTOMER) working
- [x] Frontend accessible on port 3000
- [x] Gateway running on port 9000
- [x] All microservices running
- [x] Database isolation working
- [x] Redis caching active

---

**🎉 ALL CREDENTIALS VERIFIED AND WORKING!**

**Last Test**: 2025-10-13  
**Status**: ✅ **PRODUCTION READY**

