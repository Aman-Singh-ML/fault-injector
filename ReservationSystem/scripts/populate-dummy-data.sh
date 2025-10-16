#!/bin/bash

# Hotel Reservation System - Dummy Data Population Script
# This script populates all databases with realistic test data

set -e

NAMESPACE="hotel-reservation"

echo "🏨 Hotel Reservation System - Dummy Data Population"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if pod is ready
wait_for_pod() {
    local pod_name=$1
    echo -e "${YELLOW}⏳ Waiting for $pod_name to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=$pod_name -n $NAMESPACE --timeout=300s
    echo -e "${GREEN}✅ $pod_name is ready${NC}"
}

# Function to execute SQL in PostgreSQL
execute_postgres_sql() {
    local db_name=$1
    local sql_file=$2
    local pod_name=$3
    
    echo -e "${BLUE}📊 Populating $db_name database...${NC}"
    kubectl exec -n $NAMESPACE $pod_name -- psql -U ${db_name}_user -d ${db_name}_db -f /tmp/$sql_file
    echo -e "${GREEN}✅ $db_name database populated${NC}"
}

# Function to execute MongoDB script
execute_mongo_script() {
    local script_file=$1
    local pod_name=$2
    
    echo -e "${BLUE}📊 Populating MongoDB...${NC}"
    kubectl exec -n $NAMESPACE $pod_name -- mongosh hotel_db /tmp/$script_file
    echo -e "${GREEN}✅ MongoDB populated${NC}"
}

echo "🔍 Step 1: Checking pod status..."
kubectl get pods -n $NAMESPACE

echo ""
echo "📋 Step 2: Preparing SQL scripts..."

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

# Create Booking database dummy data
cat > /tmp/booking-dummy-data.sql << 'EOF'
-- Sample bookings for testing
INSERT INTO bookings (user_id, hotel_id, hotel_name, check_in_date, check_out_date, rooms, adults, children, total_price, status) VALUES
(1, 'hotel_001', 'Grand Plaza Hotel', '2024-11-15', '2024-11-18', 1, 2, 0, 750.00, 'CONFIRMED'),
(2, 'hotel_002', 'Seaside Resort', '2024-11-20', '2024-11-25', 2, 4, 2, 1750.00, 'CONFIRMED'),
(3, 'hotel_003', 'Mountain View Lodge', '2024-12-01', '2024-12-05', 1, 2, 1, 720.00, 'PENDING'),
(1, 'hotel_004', 'Downtown Business Hotel', '2024-11-10', '2024-11-12', 1, 1, 0, 400.00, 'COMPLETED'),
(4, 'hotel_001', 'Grand Plaza Hotel', '2024-12-15', '2024-12-20', 2, 3, 1, 1250.00, 'CONFIRMED'),
(5, 'hotel_002', 'Seaside Resort', '2024-11-25', '2024-11-30', 1, 2, 0, 1750.00, 'PENDING'),
(6, 'hotel_005', 'City Center Hotel', '2024-12-05', '2024-12-08', 1, 2, 0, 600.00, 'CONFIRMED'),
(2, 'hotel_006', 'Luxury Resort & Spa', '2025-01-10', '2025-01-15', 3, 6, 3, 2400.00, 'PENDING'),
(7, 'hotel_003', 'Mountain View Lodge', '2024-12-20', '2024-12-25', 2, 4, 2, 1800.00, 'CONFIRMED'),
(8, 'hotel_007', 'Airport Hotel', '2024-11-08', '2024-11-09', 1, 1, 0, 120.00, 'COMPLETED')
ON CONFLICT DO NOTHING;
EOF

echo "✅ SQL scripts prepared"
echo ""
echo "📋 Step 3: Preparing MongoDB script..."

# Create MongoDB dummy data
cat > /tmp/mongo-dummy-data.js << 'EOF'
// Additional hotels for comprehensive testing
db.hotels.insertMany([
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
    amenities: ["WiFi", "Business Center", "Gym", "Restaurant", "Conference Rooms", "Parking", "Airport Shuttle"],
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
    description: "Stylish hotel in the heart of San Francisco with panoramic city views",
    amenities: ["WiFi", "Rooftop Bar", "Gym", "Restaurant", "Concierge", "Valet Parking"],
    images: [
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"
    ],
    total_rooms: 120,
    available_rooms: 95,
    created_at: new Date(),
    updated_at: new Date()
  }
]);
EOF

echo "✅ MongoDB script prepared"
echo ""

# Step 4: Copy scripts to pods and execute
echo "📤 Step 4: Copying scripts to database pods..."

# Get pod names using correct labels
AUTH_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgres-auth -o jsonpath='{.items[0].metadata.name}')
BOOKING_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgres-booking -o jsonpath='{.items[0].metadata.name}')
PAYMENT_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgres-payment -o jsonpath='{.items[0].metadata.name}')
MONGO_POD=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=mongodb -o jsonpath='{.items[0].metadata.name}')

echo "🔍 Found pods:"
echo "  Auth: $AUTH_POD"
echo "  Booking: $BOOKING_POD"
echo "  Payment: $PAYMENT_POD"
echo "  MongoDB: $MONGO_POD"
echo ""

# Copy and execute Auth database script
echo "📊 Step 5: Populating Auth database..."
kubectl cp /tmp/auth-dummy-data.sql $NAMESPACE/$AUTH_POD:/tmp/auth-dummy-data.sql
kubectl exec -n $NAMESPACE $AUTH_POD -- psql -U auth_user -d auth_db -f /tmp/auth-dummy-data.sql
echo -e "${GREEN}✅ Auth database populated${NC}"
echo ""

# Copy and execute Booking database script
echo "📊 Step 6: Populating Booking database..."
kubectl cp /tmp/booking-dummy-data.sql $NAMESPACE/$BOOKING_POD:/tmp/booking-dummy-data.sql
kubectl exec -n $NAMESPACE $BOOKING_POD -- psql -U booking_user -d booking_db -f /tmp/booking-dummy-data.sql
echo -e "${GREEN}✅ Booking database populated${NC}"
echo ""

# Create and populate Payment database
echo "📊 Step 7: Populating Payment database..."
cat > /tmp/payment-dummy-data.sql << 'EOF'
-- Sample payments for testing
INSERT INTO payments (booking_id, user_id, amount, currency, status, payment_method, transaction_id) VALUES
(1, 1, 750.00, 'USD', 'SUCCESS', 'OTP', 'TXN_001_' || extract(epoch from now())::text),
(2, 2, 1750.00, 'USD', 'SUCCESS', 'OTP', 'TXN_002_' || extract(epoch from now())::text),
(4, 1, 400.00, 'USD', 'SUCCESS', 'OTP', 'TXN_004_' || extract(epoch from now())::text),
(5, 4, 1250.00, 'USD', 'SUCCESS', 'OTP', 'TXN_005_' || extract(epoch from now())::text),
(7, 6, 600.00, 'USD', 'SUCCESS', 'OTP', 'TXN_007_' || extract(epoch from now())::text),
(9, 7, 1800.00, 'USD', 'PENDING', 'OTP', 'TXN_009_' || extract(epoch from now())::text),
(10, 8, 120.00, 'USD', 'SUCCESS', 'OTP', 'TXN_010_' || extract(epoch from now())::text)
ON CONFLICT (transaction_id) DO NOTHING;
EOF

kubectl cp /tmp/payment-dummy-data.sql $NAMESPACE/$PAYMENT_POD:/tmp/payment-dummy-data.sql
kubectl exec -n $NAMESPACE $PAYMENT_POD -- psql -U payment_user -d payment_db -f /tmp/payment-dummy-data.sql
echo -e "${GREEN}✅ Payment database populated${NC}"
echo ""

# Copy and execute MongoDB script
echo "📊 Step 8: Populating MongoDB..."
kubectl cp /tmp/mongo-dummy-data.js $NAMESPACE/$MONGO_POD:/tmp/mongo-dummy-data.js
kubectl exec -n $NAMESPACE $MONGO_POD -- mongosh hotel_db /tmp/mongo-dummy-data.js
echo -e "${GREEN}✅ MongoDB populated${NC}"
echo ""

# Step 9: Verification
echo "🔍 Step 9: Verifying data population..."
echo ""

echo "👥 Auth Database - Users:"
kubectl exec -n $NAMESPACE $AUTH_POD -- psql -U auth_user -d auth_db -c "SELECT id, email, first_name, last_name, role FROM users ORDER BY id;"
echo ""

echo "📅 Booking Database - Bookings:"
kubectl exec -n $NAMESPACE $BOOKING_POD -- psql -U booking_user -d booking_db -c "SELECT id, user_id, hotel_name, check_in_date, check_out_date, total_price, status FROM bookings ORDER BY id;"
echo ""

echo "💳 Payment Database - Payments:"
kubectl exec -n $NAMESPACE $PAYMENT_POD -- psql -U payment_user -d payment_db -c "SELECT id, booking_id, user_id, amount, status, payment_method FROM payments ORDER BY id;"
echo ""

echo "🏨 MongoDB - Hotels:"
kubectl exec -n $NAMESPACE $MONGO_POD -- mongosh hotel_db --eval "db.hotels.find({}, {name: 1, city: 1, rating: 1, price_per_night: 1}).pretty()"
echo ""

# Cleanup temporary files
rm -f /tmp/auth-dummy-data.sql /tmp/booking-dummy-data.sql /tmp/payment-dummy-data.sql /tmp/mongo-dummy-data.js

echo "🎉 SUCCESS! All databases have been populated with dummy data"
echo ""
echo "📋 Summary:"
echo "  👥 Auth DB: 8+ users (customers + admins)"
echo "  📅 Booking DB: 10+ sample bookings"
echo "  💳 Payment DB: 7+ payment records"
echo "  🏨 MongoDB: 5+ hotels across different cities"
echo ""
echo "🧪 You can now test the complete booking flow:"
echo "  1. Login with: a@a.com / 123456"
echo "  2. Search for hotels in New York, Miami, Denver, Chicago, or San Francisco"
echo "  3. Make bookings and test the OTP payment system"
echo "  4. View existing bookings and payment history"
echo ""
echo "🌐 Access your application at: http://localhost:3000"
