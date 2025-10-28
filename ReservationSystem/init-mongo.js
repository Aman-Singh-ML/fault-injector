// Initialize MongoDB for Search Service

// Switch to hotel database
db = db.getSiblingDB('hotel_db');

// Drop existing collection if it exists
db.hotels.drop();

// Create hotels collection with sample data
db.hotels.insertMany([
  {
    _id: "hotel_001",
    name: "Grand Plaza Hotel",
    location: "New York",
    city: "New York",
    country: "USA",
    address: "123 Broadway, New York, NY 10001",
    rating: 4.5,
    price_per_night: 250.00,
    description: "Luxury hotel in the heart of Manhattan with stunning city views",
    amenities: ["WiFi", "Pool", "Gym", "Restaurant", "Spa", "Room Service", "Parking"],
    images: [
      "https://example.com/hotel1-1.jpg",
      "https://example.com/hotel1-2.jpg"
    ],
    rooms_available: 50,
    total_rooms: 100,
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
    description: "Beautiful beachfront resort with private beach access",
    amenities: ["WiFi", "Beach", "Pool", "Bar", "Water Sports", "Restaurant", "Spa"],
    images: [
      "https://example.com/hotel2-1.jpg",
      "https://example.com/hotel2-2.jpg"
    ],
    rooms_available: 30,
    total_rooms: 75,
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
    description: "Cozy lodge with breathtaking mountain views",
    amenities: ["WiFi", "Fireplace", "Hiking", "Restaurant", "Parking"],
    images: [
      "https://example.com/hotel3-1.jpg"
    ],
    rooms_available: 20,
    total_rooms: 40,
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
    description: "Modern business hotel in downtown Chicago",
    amenities: ["WiFi", "Business Center", "Gym", "Restaurant", "Conference Rooms"],
    images: [
      "https://example.com/hotel4-1.jpg"
    ],
    rooms_available: 40,
    total_rooms: 80,
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// Create indexes for better search performance
db.hotels.createIndex({ location: 1 });
db.hotels.createIndex({ city: 1 });
db.hotels.createIndex({ rating: -1 });
db.hotels.createIndex({ price_per_night: 1 });
db.hotels.createIndex({ name: "text", description: "text" });

print("MongoDB initialized successfully with sample hotel data!");

