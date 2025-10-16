# ✅ Quick Start Checklist - Hotel Reservation System

## 🎯 Complete Setup in 5 Steps

---

## Step 1: Install Prerequisites ⚙️

### Required Software

- [ ] **Docker Desktop**
  - Download: https://www.docker.com/products/docker-desktop
  - Verify: `docker --version`
  - Verify: `docker-compose --version`

- [ ] **Node.js 18+** (for Frontend & API Gateway)
  - Download: https://nodejs.org/ (LTS version)
  - Verify: `node --version`
  - Verify: `npm --version`

### Optional (for running backend services)

- [ ] **Java 17+** (for Auth Service)
  - Download: https://adoptium.net/
  - Verify: `java --version`

- [ ] **Go 1.21+** (for Search & Payment Services)
  - Download: https://go.dev/dl/
  - Verify: `go version`

- [ ] **Python 3.11+** (for Booking & Notification Services)
  - Download: https://www.python.org/downloads/
  - Verify: `python3 --version`

---

## Step 2: Start Infrastructure 🐳

### Start All Infrastructure Services

```bash
# Navigate to project root
cd /Users/amritakumari/Documents/ReservationSystem

# Start infrastructure
docker-compose -f docker-compose-infrastructure.yml up -d

# Wait for services to be healthy (30-60 seconds)
```

### Verify Infrastructure

```bash
# Check all containers are running
docker-compose -f docker-compose-infrastructure.yml ps

# Expected output: All services should show "Up" and "healthy"
```

### Quick Test

```bash
# Test PostgreSQL
docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT COUNT(*) FROM users;"
# Expected: 2 users

# Test MongoDB
docker exec hotel-mongo mongosh -u admin -p admin hotel_db --eval "db.hotels.countDocuments()"
# Expected: 4 hotels

# Test Redis
docker exec -it hotel-redis redis-cli PING
# Expected: PONG

# Test Kafka
docker exec hotel-kafka kafka-topics --bootstrap-server localhost:9092 --list
# Expected: booking-events, payment-events

# Test RabbitMQ
curl -u admin:admin http://localhost:15672/api/overview
# Expected: JSON response
```

**✅ Infrastructure Status:**
- [ ] PostgreSQL running (port 5432)
- [ ] MongoDB running (port 27017)
- [ ] Redis running (port 6379)
- [ ] Kafka running (ports 9092/9093)
- [ ] Zookeeper running (port 2181)
- [ ] RabbitMQ running (ports 5672/15672)

---

## Step 3: Start Frontend 🎨

### Install and Run

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies (first time only)
npm install

# Start development server
npm run dev
```

### Verify Frontend

- [ ] Open browser: http://localhost:3000
- [ ] Landing page loads successfully
- [ ] Click "Login" - login page loads
- [ ] Click "Sign Up" - register page loads

**✅ Frontend Status:**
- [ ] Dependencies installed
- [ ] Dev server running on port 3000
- [ ] Landing page accessible
- [ ] No console errors

---

## Step 4: Test User Flow 👤

### Register New Account

- [ ] Go to http://localhost:3000/register
- [ ] Fill in registration form:
  - First Name: Test
  - Last Name: User
  - Email: newuser@test.com
  - Phone: +1234567890
  - Password: password123
  - Confirm Password: password123
- [ ] Click "Create Account"
- [ ] Redirected to login page

### Login with Demo Account

- [ ] Go to http://localhost:3000/login
- [ ] Use demo credentials:
  - **Customer**: test@hotel.com / password123
  - **Admin**: admin@hotel.com / password123
- [ ] Click "Sign in"
- [ ] Redirected to dashboard

### Browse Hotels

- [ ] Dashboard shows hotel listings
- [ ] Hotel cards display:
  - Hotel name
  - Location
  - Rating
  - Price
  - Amenities
  - "Book Now" button

### Search Hotels

- [ ] Click "Search" in navigation
- [ ] Try filters:
  - City: New York
  - Check-in: Tomorrow
  - Check-out: Day after tomorrow
  - Guests: 2
  - Price range: 50-200
  - Rating: 4+
- [ ] Click "Apply Filters"
- [ ] Results update

### View Profile

- [ ] Click user avatar in top right
- [ ] Click "Profile"
- [ ] Profile page shows user information
- [ ] Try updating first name
- [ ] Click "Save Changes"
- [ ] Success message appears

**✅ User Flow Status:**
- [ ] Registration works
- [ ] Login works
- [ ] Dashboard loads
- [ ] Search works
- [ ] Profile updates work

---

## Step 5: Test Admin Flow 👨‍💼

### Login as Admin

- [ ] Logout if logged in
- [ ] Login with admin credentials:
  - Email: admin@hotel.com
  - Password: password123
- [ ] Notice "Admin" link in navigation

### Admin Dashboard

- [ ] Click "Admin" in navigation
- [ ] Dashboard shows:
  - Total Users count
  - Total Hotels count
  - Total Bookings count
  - Total Revenue
  - Quick action cards

### Manage Users

- [ ] Click "Manage Users" or go to /admin/users
- [ ] User table displays:
  - User names
  - Email addresses
  - Roles (ADMIN/CUSTOMER)
  - Status (Active/Inactive)
  - Edit/Delete buttons

### Manage Hotels

- [ ] Click "Manage Hotels" or go to /admin/hotels
- [ ] Hotel grid displays all hotels
- [ ] Each card shows:
  - Hotel image
  - Name, location, rating
  - Price and availability
  - Edit/Delete buttons

### Manage Bookings

- [ ] Click "Manage Bookings" or go to /admin/bookings
- [ ] Booking table displays:
  - Booking IDs
  - Hotel names
  - Customer info
  - Dates
  - Status
  - Status dropdown to update

**✅ Admin Flow Status:**
- [ ] Admin login works
- [ ] Admin dashboard loads
- [ ] User management accessible
- [ ] Hotel management accessible
- [ ] Booking management accessible

---

## 🎉 Success Criteria

### Infrastructure ✅
- [x] All 6 Docker containers running
- [x] Sample data loaded
- [x] All ports accessible

### Frontend ✅
- [x] Next.js app running on port 3000
- [x] All pages accessible
- [x] No build errors
- [x] Responsive design works

### User Features ✅
- [ ] Registration works
- [ ] Login works
- [ ] Dashboard displays hotels
- [ ] Search with filters works
- [ ] Profile management works
- [ ] Logout works

### Admin Features ✅
- [ ] Admin login works
- [ ] Admin dashboard shows stats
- [ ] User management works
- [ ] Hotel management works
- [ ] Booking management works

---

## 🐛 Common Issues & Solutions

### Issue: Docker containers won't start
**Solution:**
```bash
docker-compose -f docker-compose-infrastructure.yml down -v
docker-compose -f docker-compose-infrastructure.yml up -d
```

### Issue: npm command not found
**Solution:**
Install Node.js from https://nodejs.org/

### Issue: Port already in use
**Solution:**
```bash
# Find process using port
lsof -i :3000  # or :9000, :5432, etc.

# Kill process
kill -9 <PID>
```

### Issue: Frontend can't connect to API
**Solution:**
- Check API Gateway is running on port 9000
- Verify `.env.local` has correct API URL
- Check browser console for CORS errors

### Issue: Login fails
**Solution:**
- Verify PostgreSQL is running
- Check demo users exist:
  ```bash
  docker exec -it hotel-postgres psql -U admin -d hotel_db -c "SELECT email FROM users;"
  ```
- Clear browser localStorage and try again

---

## 📚 Documentation Reference

| Document | Purpose |
|----------|---------|
| `FRONTEND_COMPLETE_SUMMARY.md` | Frontend overview |
| `FRONTEND_SETUP_GUIDE.md` | Detailed frontend setup |
| `COMPLETE_SYSTEM_GUIDE.md` | Full system guide |
| `SYSTEM_ARCHITECTURE.md` | Architecture diagrams |
| `INFRASTRUCTURE_READY.md` | Infrastructure details |
| `RUN_SERVICES_GUIDE.md` | Backend service setup |
| `frontend/README.md` | Frontend technical docs |

---

## 🎯 Next Steps After Setup

### For Development
1. Start backend services (Auth, Search, Booking, Payment, Notification)
2. Start API Gateway
3. Test complete booking flow
4. Test payment processing
5. Test notifications

### For Testing
1. Create test bookings
2. Test payment flows
3. Test notification delivery
4. Test admin operations
5. Test error handling

### For Production
1. Build frontend: `npm run build`
2. Configure environment variables
3. Set up SSL certificates
4. Configure load balancers
5. Set up monitoring

---

## ✅ Final Checklist

Before considering setup complete:

- [ ] Infrastructure running and healthy
- [ ] Frontend accessible at http://localhost:3000
- [ ] Can register new user
- [ ] Can login as customer
- [ ] Can login as admin
- [ ] Dashboard shows hotels
- [ ] Search filters work
- [ ] Admin dashboard accessible
- [ ] No console errors
- [ ] All pages load correctly

---

## 🚀 You're Ready!

If all checkboxes are checked, your Hotel Reservation System is ready to use!

**Access the application:**
- **Frontend**: http://localhost:3000
- **RabbitMQ UI**: http://localhost:15672 (admin/admin)

**Demo Credentials:**
- **Customer**: test@hotel.com / password123
- **Admin**: admin@hotel.com / password123

---

**Happy Coding! 🎊**

