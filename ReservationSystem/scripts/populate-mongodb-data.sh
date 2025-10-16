#!/bin/bash

# MongoDB Dummy Data Population Script
# This script populates MongoDB with hotel data using proper authentication

set -e

NAMESPACE="hotel-reservation"
MONGO_POD="mongodb-0"

echo "🏨 MongoDB Dummy Data Population"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Step 1: Creating MongoDB dummy data script...${NC}"

# Create MongoDB script with authentication
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

// Create indexes for better search performance (skip if they exist)
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

// Drop existing text index if it exists and create new one
try {
  db.hotels.dropIndex("name_text_description_text");
  print("🗑️ Dropped old text index");
} catch (e) {
  print("ℹ️ No old text index to drop");
}

try {
  db.hotels.createIndex({ "name": "text", "description": "text", "city": "text" });
  print("✅ Created new text search index");
} catch (e) {
  print("ℹ️ Text index creation skipped: " + e.message);
}

// Verify data
const count = db.hotels.countDocuments();
print("📊 Total hotels in database: " + count);

// Show sample data
print("🏨 Sample hotels:");
db.hotels.find({}, {name: 1, city: 1, rating: 1, price_per_night: 1}).forEach(printjson);

print("🎉 MongoDB population completed successfully!");
EOF

echo -e "${GREEN}✅ MongoDB script created${NC}"
echo ""

echo -e "${BLUE}📤 Step 2: Copying script to MongoDB pod...${NC}"
kubectl cp /tmp/mongo-hotels-data.js $NAMESPACE/$MONGO_POD:/tmp/mongo-hotels-data.js

echo -e "${GREEN}✅ Script copied to pod${NC}"
echo ""

echo -e "${BLUE}📊 Step 3: Executing MongoDB script...${NC}"
kubectl exec -n $NAMESPACE $MONGO_POD -- mongosh --authenticationDatabase admin -u search_user -p search_pass search_db /tmp/mongo-hotels-data.js

echo ""
echo -e "${GREEN}✅ MongoDB populated successfully!${NC}"
echo ""

echo -e "${BLUE}🔍 Step 4: Verifying data...${NC}"
kubectl exec -n $NAMESPACE $MONGO_POD -- mongosh --authenticationDatabase admin -u search_user -p search_pass search_db --eval "
print('📊 Database: search_db');
print('🏨 Hotels count: ' + db.hotels.countDocuments());
print('🏙️ Cities available:');
db.hotels.distinct('city').forEach(city => print('  - ' + city));
"

# Cleanup
rm -f /tmp/mongo-hotels-data.js

echo ""
echo -e "${GREEN}🎉 SUCCESS! MongoDB has been populated with hotel data${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo -e "  🏨 Hotels: 6 luxury hotels across major US cities"
echo -e "  🏙️ Cities: New York, Miami, Denver, Chicago, San Francisco, Las Vegas"
echo -e "  💰 Price range: $180 - $450 per night"
echo -e "  ⭐ Ratings: 4.2 - 4.9 stars"
echo ""
echo -e "${BLUE}🧪 You can now test hotel search functionality!${NC}"
