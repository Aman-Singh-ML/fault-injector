-- Initialize Auth Database for Hotel Reservation System
-- Database: auth_db
-- User: auth_user

-- Create users table for Auth Service
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(50) DEFAULT 'CUSTOMER',
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_enabled ON users(enabled);

-- Insert sample data for testing
-- Passwords: admin@hotel.com = admin123, test@hotel.com = password123, a@a.com = 123456
INSERT INTO users (email, password, first_name, last_name, phone_number, role)
VALUES
    ('admin@hotel.com', '$2b$10$Cwk7rDfu0Tfml3C9RIqCpeeL9Qg57CVwfSDhk20xxri8QdxWmupGG', 'Admin', 'User', '+1234567890', 'ADMIN'),
    ('test@hotel.com', '$2b$10$WbbilC0KDnsJJRqVnk59F.SVu0Iy3nq0aDuKlqlaw/ODOVKuup/kS', 'Test', 'User', '+1234567891', 'CUSTOMER'),
    ('a@a.com', '$2b$10$W9YyIgWhJETiPGwf1kFgwOA3h1hWaDYdn3sTZsA08/uGx67VOnnhq', 'A', 'User', '+1111111111', 'CUSTOMER')
ON CONFLICT (email) DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for users table
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

