#!/bin/bash

# Hotel Reservation System - Complete Data Population Script
# This script populates all databases (PostgreSQL + MongoDB) with comprehensive test data
# NO HELM UPGRADES - Only data population

set -e

NAMESPACE="hotel-reservation"

echo "🏨 Hotel Reservation System - Complete Data Population"
echo "====================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if pod exists and is ready
check_pod_ready() {
    local pod_name=$1
    if [ -z "$pod_name" ]; then
        echo -e "${RED}❌ Pod $2 not found${NC}"
        return 1
    fi
    
    local ready=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$ready" != "True" ]; then
        echo -e "${YELLOW}⏳ Waiting for $pod_name to be ready...${NC}"
        kubectl wait --for=condition=ready pod $pod_name -n $NAMESPACE --timeout=300s
    fi
    echo -e "${GREEN}✅ $pod_name is ready${NC}"
}

echo "🔍 Step 1: Checking pod status..."
kubectl get pods -n $NAMESPACE

echo ""
echo "🔍 Step 2: Getting pod names..."

# Get pod names using correct labels
AUTH_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgres-auth -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
BOOKING_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgres-booking -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
PAYMENT_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgres-payment -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
MONGO_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=mongodb -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

echo "🔍 Found pods:"
echo "  Auth: $AUTH_POD"
echo "  Booking: $BOOKING_POD"
echo "  Payment: $PAYMENT_POD"
echo "  MongoDB: $MONGO_POD"
echo ""

# Check if all pods are ready
check_pod_ready "$AUTH_POD" "postgres-auth"
check_pod_ready "$BOOKING_POD" "postgres-booking"
check_pod_ready "$PAYMENT_POD" "postgres-payment"
check_pod_ready "$MONGO_POD" "mongodb"

echo ""
echo "📋 Step 3: Preparing database scripts..."

# Create Auth database dummy data
cat > /tmp/auth-dummy-data.sql << 'EOF'
-- Additional users for testing
INSERT INTO users (email, password, first_name, last_name, phone_number, role) VALUES
('john.doe@email.com', '$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq', 'John', 'Doe', '+1-555-0101', 'CUSTOMER'),
('jane.smith@email.com', '$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq', 'Jane', 'Smith', '+1-555-0102', 'CUSTOMER'),
('mike.wilson@email.com', '$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq', 'Mike', 'Wilson', '+1-555-0103', 'CUSTOMER'),
('sarah.johnson@email.com', '$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq', 'Sarah', 'Johnson', '+1-555-0104', 'CUSTOMER'),
('david.brown@email.com', '$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq', 'David', 'Brown', '+1-555-0105', 'CUSTOMER'),
('lisa.davis@email.com', '$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq', 'Lisa', 'Davis', '+1-555-0106', 'CUSTOMER'),
('manager@hotel.com', '$2b$10$Cwk7rDfu0Tfml3C9RIqCpeeL9Qg57CVwfSDhk20xxri8QdxWmupGG', 'Hotel', 'Manager', '+1-555-0200', 'ADMIN'),
('support@hotel.com', '$2b$10$Cwk7rDfu0Tfml3C9RIqCpeeL9Qg57CVwfSDhk20xxri8QdxWmupGG', 'Customer', 'Support', '+1-555-0300', 'ADMIN')
ON CONFLICT (email) DO NOTHING;

-- Update user statistics
UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE email IN (
    'john.doe@email.com', 'jane.smith@email.com', 'mike.wilson@email.com',
    'sarah.johnson@email.com', 'david.brown@email.com', 'lisa.davis@email.com'
);
EOF

# Create Booking database schema fix and dummy data
cat > /tmp/booking-schema-and-data.sql << 'EOF'
-- Fix booking schema - add missing columns if they don't exist
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'PENDING',
ADD COLUMN IF NOT EXISTS payment_id INTEGER,
ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(255);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON bookings(payment_status);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_hotel_id ON bookings(hotel_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_check_in_date ON bookings(check_in_date);
CREATE INDEX IF NOT EXISTS idx_bookings_check_out_date ON bookings(check_out_date);

-- Sample bookings for testing
INSERT INTO bookings (user_id, hotel_id, hotel_name, check_in_date, check_out_date, rooms, adults, children, total_price, status, payment_status) VALUES
(1, 'hotel_001', 'Grand Plaza Hotel', '2024-11-15', '2024-11-18', 1, 2, 0, 750.00, 'CONFIRMED', 'SUCCESS'),
(2, 'hotel_002', 'Seaside Resort', '2024-11-20', '2024-11-25', 2, 4, 2, 1750.00, 'CONFIRMED', 'SUCCESS'),
(3, 'hotel_003', 'Mountain View Lodge', '2024-12-01', '2024-12-05', 1, 2, 1, 720.00, 'PENDING', 'PENDING'),
(1, 'hotel_004', 'Downtown Business Hotel', '2024-11-10', '2024-11-12', 1, 1, 0, 400.00, 'COMPLETED', 'SUCCESS'),
(4, 'hotel_001', 'Grand Plaza Hotel', '2024-12-15', '2024-12-20', 2, 3, 1, 1250.00, 'CONFIRMED', 'SUCCESS'),
(5, 'hotel_002', 'Seaside Resort', '2024-11-25', '2024-11-30', 1, 2, 0, 1750.00, 'PENDING', 'PENDING'),
(6, 'hotel_005', 'City Center Hotel', '2024-12-05', '2024-12-08', 1, 2, 0, 600.00, 'CONFIRMED', 'SUCCESS'),
(2, 'hotel_006', 'Luxury Resort & Spa', '2025-01-10', '2025-01-15', 3, 6, 3, 2400.00, 'PENDING', 'PENDING'),
(7, 'hotel_003', 'Mountain View Lodge', '2024-12-20', '2024-12-25', 2, 4, 2, 1800.00, 'CONFIRMED', 'SUCCESS'),
(8, 'hotel_007', 'Airport Hotel', '2024-11-08', '2024-11-09', 1, 1, 0, 120.00, 'COMPLETED', 'SUCCESS')
ON CONFLICT DO NOTHING;

-- Update existing bookings with payment status if null
UPDATE bookings SET payment_status = 'SUCCESS' WHERE status IN ('CONFIRMED', 'COMPLETED') AND payment_status IS NULL;
UPDATE bookings SET payment_status = 'PENDING' WHERE status = 'PENDING' AND payment_status IS NULL;
UPDATE bookings SET payment_status = 'REFUNDED' WHERE status = 'CANCELLED' AND payment_status IS NULL;
EOF

# Create Payment database schema fix and dummy data
cat > /tmp/payment-schema-and-data.sql << 'EOF'
-- Fix payment schema - add missing OTP column if it doesn't exist
ALTER TABLE payments ADD COLUMN IF NOT EXISTS otp VARCHAR(6);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS otp_expires_at TIMESTAMP;

-- Add missing columns for compatibility
ALTER TABLE payments ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'USD';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'OTP';

-- Fix existing NULL values and constraints
UPDATE payments SET payment_method = 'OTP' WHERE payment_method IS NULL;
UPDATE payments SET currency = 'USD' WHERE currency IS NULL;

-- Ensure proper defaults for future inserts
ALTER TABLE payments ALTER COLUMN payment_method SET DEFAULT 'OTP';
ALTER TABLE payments ALTER COLUMN currency SET DEFAULT 'USD';

-- Sample payments for testing
INSERT INTO payments (booking_id, user_id, amount, currency, status, payment_method, transaction_id, otp) VALUES
(1, 1, 750.00, 'USD', 'SUCCESS', 'OTP', 'TXN_001_' || extract(epoch from now())::text, '123456'),
(2, 2, 1750.00, 'USD', 'SUCCESS', 'OTP', 'TXN_002_' || extract(epoch from now())::text, '234567'),
(4, 1, 400.00, 'USD', 'SUCCESS', 'OTP', 'TXN_004_' || extract(epoch from now())::text, '345678'),
(5, 4, 1250.00, 'USD', 'SUCCESS', 'OTP', 'TXN_005_' || extract(epoch from now())::text, '456789'),
(7, 6, 600.00, 'USD', 'SUCCESS', 'OTP', 'TXN_007_' || extract(epoch from now())::text, '567890'),
(9, 7, 1800.00, 'USD', 'SUCCESS', 'OTP', 'TXN_009_' || extract(epoch from now())::text, '678901'),
(10, 8, 120.00, 'USD', 'SUCCESS', 'OTP', 'TXN_010_' || extract(epoch from now())::text, '789012')
ON CONFLICT (transaction_id) DO NOTHING;
EOF

echo -e "${GREEN}✅ SQL scripts prepared${NC}"
echo ""

echo "📋 Step 4: Preparing MongoDB script..."

# Create comprehensive MongoDB script with authentication
cat > /tmp/mongo-hotels-data.js << 'EOF'
// MongoDB Hotel Data Population Script
// Connect to the search_db database with authentication

// Switch to search_db database
db = db.getSiblingDB('search_db');

// Authenticate with search_user credentials
db.auth('search_user', 'search_pass');

print("✅ Successfully authenticated to search_db");

// Clear existing hotels collection (optional)
db.hotels.deleteMany({});
print("🗑️ Cleared existing hotels data");

// Insert comprehensive hotel data
const hotels = [
  {
    _id: "hotel_001",
    name: "Grand Plaza Hotel",
    location: "New York",
    city: "New York",
    country: "USA",
    address: "123 Broadway, New York, NY 10001",
    rating: 4.5,
    price_per_night: 250.00,
    description: "Luxury hotel in the heart of Manhattan with stunning city views and premium amenities",
    amenities: ["WiFi", "Pool", "Gym", "Restaurant", "Spa", "Room Service", "Concierge", "Valet Parking"],
    images: [
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
      "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800"
    ],
    total_rooms: 100,
    available_rooms: 85,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_002",
    name: "Seaside Resort",
    location: "Miami",
    city: "Miami",
    country: "USA",
    address: "456 Ocean Drive, Miami, FL 33139",
    rating: 4.8,
    price_per_night: 350.00,
    description: "Beautiful beachfront resort with private beach access and luxury spa services",
    amenities: ["WiFi", "Private Beach", "Pool", "Bar", "Water Sports", "Restaurant", "Spa", "Tennis Court"],
    images: [
      "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800",
      "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800"
    ],
    total_rooms: 75,
    available_rooms: 60,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_003",
    name: "Mountain View Lodge",
    location: "Denver",
    city: "Denver",
    country: "USA",
    address: "789 Mountain Road, Denver, CO 80202",
    rating: 4.3,
    price_per_night: 180.00,
    description: "Cozy mountain lodge with breathtaking views and outdoor adventure activities",
    amenities: ["WiFi", "Mountain Views", "Fireplace", "Hiking Trails", "Restaurant", "Ski Storage", "Hot Tub"],
    images: [
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"
    ],
    total_rooms: 40,
    available_rooms: 32,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_004",
    name: "Downtown Business Hotel",
    location: "Chicago",
    city: "Chicago",
    country: "USA",
    address: "321 Michigan Avenue, Chicago, IL 60601",
    rating: 4.2,
    price_per_night: 200.00,
    description: "Modern business hotel in downtown Chicago with excellent conference facilities",
    amenities: ["WiFi", "Business Center", "Gym", "Restaurant", "Conference Rooms", "Airport Shuttle", "Parking"],
    images: [
      "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800",
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800"
    ],
    total_rooms: 80,
    available_rooms: 65,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_005",
    name: "City Center Hotel",
    location: "San Francisco",
    city: "San Francisco",
    country: "USA",
    address: "555 Market Street, San Francisco, CA 94105",
    rating: 4.4,
    price_per_night: 280.00,
    description: "Stylish hotel in the heart of San Francisco with panoramic city and bay views",
    amenities: ["WiFi", "City Views", "Rooftop Bar", "Gym", "Restaurant", "Concierge", "Valet Parking"],
    images: [
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"
    ],
    total_rooms: 120,
    available_rooms: 95,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_006",
    name: "Luxury Resort & Spa",
    location: "Las Vegas",
    city: "Las Vegas",
    country: "USA",
    address: "3570 Las Vegas Blvd S, Las Vegas, NV 89109",
    rating: 4.9,
    price_per_night: 450.00,
    description: "Ultra-luxury resort with world-class spa, multiple pools, and premium dining experiences",
    amenities: ["WiFi", "Casino", "Spa", "Multiple Pools", "Fine Dining", "Shows", "Valet Parking", "Concierge"],
    images: [
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
      "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800"
    ],
    total_rooms: 200,
    available_rooms: 150,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_007",
    name: "Airport Hotel",
    location: "Los Angeles",
    city: "Los Angeles",
    country: "USA",
    address: "1 World Way, Los Angeles, CA 90045",
    rating: 3.8,
    price_per_night: 120.00,
    description: "Convenient airport hotel with shuttle service and business facilities",
    amenities: ["WiFi", "Airport Shuttle", "Business Center", "Restaurant", "Gym", "24/7 Front Desk"],
    images: [
      "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800",
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800"
    ],
    total_rooms: 150,
    available_rooms: 120,
    created_at: new Date(),
    updated_at: new Date()
  }
];

// Insert hotels one by one to handle conflicts
let insertedCount = 0;
hotels.forEach(hotel => {
  try {
    db.hotels.insertOne(hotel);
    insertedCount++;
    print("✅ Inserted: " + hotel.name);
  } catch (e) {
    if (e.code === 11000) {
      // Duplicate key error - update instead
      db.hotels.replaceOne({_id: hotel._id}, hotel, {upsert: true});
      print("🔄 Updated: " + hotel.name);
      insertedCount++;
    } else {
      print("❌ Error inserting " + hotel.name + ": " + e.message);
    }
  }
});

print("✅ Processed " + insertedCount + " hotels");

// Create indexes for better search performance
try {
  db.hotels.createIndex({ "city": 1 });
  print("✅ Created city index");
} catch (e) {
  print("ℹ️ City index already exists");
}

try {
  db.hotels.createIndex({ "rating": -1 });
  print("✅ Created rating index");
} catch (e) {
  print("ℹ️ Rating index already exists");
}

try {
  db.hotels.createIndex({ "price_per_night": 1 });
  print("✅ Created price index");
} catch (e) {
  print("ℹ️ Price index already exists");
}

try {
  db.hotels.createIndex({ "name": "text", "description": "text", "city": "text" });
  print("✅ Created text search index");
} catch (e) {
  print("ℹ️ Text index creation skipped: " + e.message);
}

// Verify data
const count = db.hotels.countDocuments();
print("📊 Total hotels in database: " + count);

print("🎉 MongoDB population completed successfully!");
EOF

echo -e "${GREEN}✅ MongoDB script prepared${NC}"
echo ""

echo "📤 Step 5: Populating Auth Database..."
kubectl cp /tmp/auth-dummy-data.sql $NAMESPACE/$AUTH_POD:/tmp/auth-dummy-data.sql
kubectl exec -n $NAMESPACE $AUTH_POD -- psql -U auth_user -d auth_db -f /tmp/auth-dummy-data.sql
echo -e "${GREEN}✅ Auth database populated${NC}"
echo ""

echo "📤 Step 6: Populating Booking Database (with schema fixes)..."
kubectl cp /tmp/booking-schema-and-data.sql $NAMESPACE/$BOOKING_POD:/tmp/booking-schema-and-data.sql
kubectl exec -n $NAMESPACE $BOOKING_POD -- psql -U booking_user -d booking_db -f /tmp/booking-schema-and-data.sql
echo -e "${GREEN}✅ Booking database populated and schema fixed${NC}"
echo ""

echo "📤 Step 7: Populating Payment Database (with schema fixes)..."
kubectl cp /tmp/payment-schema-and-data.sql $NAMESPACE/$PAYMENT_POD:/tmp/payment-schema-and-data.sql
kubectl exec -n $NAMESPACE $PAYMENT_POD -- psql -U payment_user -d payment_db -f /tmp/payment-schema-and-data.sql
echo -e "${GREEN}✅ Payment database populated and schema fixed${NC}"
echo ""

echo "📤 Step 8: Populating MongoDB..."
kubectl cp /tmp/mongo-hotels-data.js $NAMESPACE/$MONGO_POD:/tmp/mongo-hotels-data.js
kubectl exec -n $NAMESPACE $MONGO_POD -- mongosh --authenticationDatabase admin -u search_user -p search_pass search_db /tmp/mongo-hotels-data.js
echo -e "${GREEN}✅ MongoDB populated${NC}"
echo ""

echo "🔍 Step 9: Verifying data population..."
echo ""

echo -e "${CYAN}👥 Auth Database - Users:${NC}"
kubectl exec -n $NAMESPACE $AUTH_POD -- psql -U auth_user -d auth_db -c "SELECT id, email, first_name, last_name, role FROM users ORDER BY id;"
echo ""

echo -e "${CYAN}📅 Booking Database - Bookings:${NC}"
kubectl exec -n $NAMESPACE $BOOKING_POD -- psql -U booking_user -d booking_db -c "SELECT id, user_id, hotel_name, check_in_date, check_out_date, total_price, status, payment_status FROM bookings ORDER BY id;"
echo ""

echo -e "${CYAN}💳 Payment Database - Payments:${NC}"
kubectl exec -n $NAMESPACE $PAYMENT_POD -- psql -U payment_user -d payment_db -c "SELECT id, booking_id, user_id, amount, status, payment_method FROM payments ORDER BY id;"
echo ""

echo -e "${CYAN}🏨 MongoDB - Hotels:${NC}"
kubectl exec -n $NAMESPACE $MONGO_POD -- mongosh --authenticationDatabase admin -u search_user -p search_pass search_db --eval "
print('📊 Database: search_db');
print('🏨 Hotels count: ' + db.hotels.countDocuments());
print('🏙️ Cities available:');
db.hotels.distinct('city').forEach(city => print('  - ' + city));
print('🏨 Sample hotels:');
db.hotels.find({}, {name: 1, city: 1, rating: 1, price_per_night: 1}).limit(5).forEach(printjson);
"
echo ""

# Cleanup temporary files
rm -f /tmp/auth-dummy-data.sql /tmp/booking-schema-and-data.sql /tmp/payment-schema-and-data.sql /tmp/mongo-hotels-data.js

echo -e "${GREEN}🎉 SUCCESS! All databases have been populated with comprehensive data${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "${CYAN}  👥 Auth DB: 8+ users (customers + admins)${NC}"
echo -e "${CYAN}  📅 Booking DB: 10+ sample bookings + schema fixes${NC}"
echo -e "${CYAN}  💳 Payment DB: 7+ payment records${NC}"
echo -e "${CYAN}  🏨 MongoDB: 7+ hotels across major US cities${NC}"
echo ""
echo -e "${BLUE}🏙️ Available Cities:${NC}"
echo -e "${CYAN}  • New York, Miami, Denver, Chicago${NC}"
echo -e "${CYAN}  • San Francisco, Las Vegas, Los Angeles${NC}"
echo ""
echo -e "${BLUE}🧪 Test Credentials:${NC}"
echo -e "${CYAN}  Admin: admin@hotel.com / admin123${NC}"
echo -e "${CYAN}  Customer: a@a.com / 123456${NC}"
echo -e "${CYAN}  Customer: john.doe@email.com / password123${NC}"
echo ""
echo -e "${BLUE}🌐 Next Steps:${NC}"
echo -e "${CYAN}  1. Access your application via the external IP${NC}"
echo -e "${CYAN}  2. Test hotel search in different cities${NC}"
echo -e "${CYAN}  3. Create bookings and test payment flow${NC}"
echo -e "${CYAN}  4. View existing bookings and payment history${NC}"
echo ""
