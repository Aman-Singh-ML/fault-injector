// Update hotels with rooms_available field
db = db.getSiblingDB('hotel_db');

db.hotels.updateOne({_id: 'hotel_001'}, {$set: {rooms_available: 50}});
db.hotels.updateOne({_id: 'hotel_002'}, {$set: {rooms_available: 30}});
db.hotels.updateOne({_id: 'hotel_003'}, {$set: {rooms_available: 20}});
db.hotels.updateOne({_id: 'hotel_004'}, {$set: {rooms_available: 40}});

print('✅ Hotels updated with rooms_available field');
db.hotels.find({}, {name: 1, rooms_available: 1, total_rooms: 1}).pretty();

