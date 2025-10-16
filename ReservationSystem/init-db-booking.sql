-- Initialize Booking Database for Hotel Reservation System
-- Database: booking_db
-- User: booking_user

-- Create bookings table for Booking Service
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    hotel_id VARCHAR(100) NOT NULL,
    hotel_name VARCHAR(255) NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    rooms INTEGER NOT NULL DEFAULT 1,
    adults INTEGER NOT NULL DEFAULT 2,
    children INTEGER NOT NULL DEFAULT 0,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    payment_status VARCHAR(50) DEFAULT 'PENDING',
    payment_id INTEGER,
    transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_hotel_id ON bookings(hotel_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON bookings(payment_status);
CREATE INDEX IF NOT EXISTS idx_bookings_check_in_date ON bookings(check_in_date);
CREATE INDEX IF NOT EXISTS idx_bookings_check_out_date ON bookings(check_out_date);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for bookings table
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create room availability cache table (for Redis fallback)
CREATE TABLE IF NOT EXISTS room_availability (
    id SERIAL PRIMARY KEY,
    hotel_id VARCHAR(100) NOT NULL,
    room_type VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    available_rooms INTEGER NOT NULL DEFAULT 0,
    total_rooms INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(hotel_id, room_type, date)
);

CREATE INDEX IF NOT EXISTS idx_room_availability_hotel_date ON room_availability(hotel_id, date);

