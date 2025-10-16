// Extended Hotels Data for MongoDB
// This script adds more comprehensive hotel data for testing

db.hotels.insertMany([
  {
    _id: "hotel_006",
    name: "Luxury Resort & Spa",
    location: "Las Vegas",
    city: "Las Vegas",
    country: "USA",
    address: "3570 Las Vegas Blvd S, Las Vegas, NV 89109",
    rating: 4.9,
    price_per_night: 450.00,
    description: "Ultra-luxury resort with world-class spa, multiple pools, and premium dining",
    amenities: ["WiFi", "Casino", "Spa", "Multiple Pools", "Fine Dining", "Shows", "Valet Parking", "Concierge"],
    images: [
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
      "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800",
      "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800"
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
    description: "Convenient airport hotel with 24/7 shuttle service and business facilities",
    amenities: ["WiFi", "Airport Shuttle", "Business Center", "Gym", "Restaurant", "24/7 Front Desk"],
    images: [
      "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800"
    ],
    total_rooms: 300,
    available_rooms: 280,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_008",
    name: "Historic Downtown Inn",
    location: "Boston",
    city: "Boston",
    country: "USA",
    address: "85 Devonshire Street, Boston, MA 02109",
    rating: 4.1,
    price_per_night: 220.00,
    description: "Charming historic hotel in the heart of Boston's financial district",
    amenities: ["WiFi", "Historic Architecture", "Restaurant", "Bar", "Concierge", "Parking"],
    images: [
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"
    ],
    total_rooms: 60,
    available_rooms: 45,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_009",
    name: "Waterfront Resort",
    location: "Seattle",
    city: "Seattle",
    country: "USA",
    address: "1112 4th Avenue, Seattle, WA 98101",
    rating: 4.6,
    price_per_night: 320.00,
    description: "Modern waterfront resort with stunning views of Puget Sound and the Olympic Mountains",
    amenities: ["WiFi", "Waterfront Views", "Spa", "Pool", "Restaurant", "Bar", "Fitness Center", "Marina"],
    images: [
      "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800",
      "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800"
    ],
    total_rooms: 150,
    available_rooms: 120,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_010",
    name: "Desert Oasis Resort",
    location: "Phoenix",
    city: "Phoenix",
    country: "USA",
    address: "5594 E Lincoln Dr, Scottsdale, AZ 85253",
    rating: 4.7,
    price_per_night: 380.00,
    description: "Luxury desert resort with championship golf course and world-class spa",
    amenities: ["WiFi", "Golf Course", "Spa", "Multiple Pools", "Tennis Court", "Fine Dining", "Desert Tours"],
    images: [
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
      "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800"
    ],
    total_rooms: 180,
    available_rooms: 140,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_011",
    name: "Riverside Lodge",
    location: "Portland",
    city: "Portland",
    country: "USA",
    address: "1510 SW Harbor Way, Portland, OR 97201",
    rating: 4.0,
    price_per_night: 190.00,
    description: "Eco-friendly lodge along the Willamette River with sustainable practices",
    amenities: ["WiFi", "River Views", "Eco-Friendly", "Restaurant", "Bike Rentals", "Hiking Trails"],
    images: [
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800"
    ],
    total_rooms: 90,
    available_rooms: 75,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "hotel_012",
    name: "Metropolitan Suites",
    location: "Atlanta",
    city: "Atlanta",
    country: "USA",
    address: "265 Peachtree Center Ave NE, Atlanta, GA 30303",
    rating: 4.3,
    price_per_night: 240.00,
    description: "Modern all-suite hotel in downtown Atlanta with spacious accommodations",
    amenities: ["WiFi", "Suites", "Kitchen", "Business Center", "Gym", "Restaurant", "Parking"],
    images: [
      "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800",
      "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"
    ],
    total_rooms: 220,
    available_rooms: 180,
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// Create indexes for better search performance
db.hotels.createIndex({ "city": 1 });
db.hotels.createIndex({ "rating": -1 });
db.hotels.createIndex({ "price_per_night": 1 });
db.hotels.createIndex({ "name": "text", "description": "text", "city": "text" });

print("✅ Extended hotel data inserted successfully!");
print("📊 Total hotels in database: " + db.hotels.countDocuments());
print("🏙️ Cities available: New York, Miami, Denver, Chicago, San Francisco, Las Vegas, Los Angeles, Boston, Seattle, Phoenix, Portland, Atlanta");
