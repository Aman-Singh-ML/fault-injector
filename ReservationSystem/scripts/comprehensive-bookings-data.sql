-- Comprehensive Booking Data for Testing
-- This script adds realistic booking scenarios across different time periods

-- Additional realistic bookings with various statuses
INSERT INTO bookings (user_id, hotel_id, hotel_name, check_in_date, check_out_date, rooms, adults, children, total_price, status, payment_status) VALUES
-- Recent completed bookings
(1, 'hotel_007', 'Airport Hotel', '2024-10-01', '2024-10-02', 1, 1, 0, 120.00, 'COMPLETED', 'SUCCESS'),
(2, 'hotel_008', 'Historic Downtown Inn', '2024-10-05', '2024-10-08', 1, 2, 0, 660.00, 'COMPLETED', 'SUCCESS'),
(3, 'hotel_009', 'Waterfront Resort', '2024-10-10', '2024-10-13', 2, 4, 1, 960.00, 'COMPLETED', 'SUCCESS'),

-- Current/upcoming confirmed bookings
(4, 'hotel_010', 'Desert Oasis Resort', '2024-11-12', '2024-11-16', 1, 2, 0, 1520.00, 'CONFIRMED', 'SUCCESS'),
(5, 'hotel_011', 'Riverside Lodge', '2024-11-18', '2024-11-21', 1, 2, 1, 570.00, 'CONFIRMED', 'SUCCESS'),
(6, 'hotel_012', 'Metropolitan Suites', '2024-11-22', '2024-11-25', 2, 3, 2, 720.00, 'CONFIRMED', 'SUCCESS'),
(1, 'hotel_006', 'Luxury Resort & Spa', '2024-12-10', '2024-12-15', 3, 6, 2, 2250.00, 'CONFIRMED', 'SUCCESS'),

-- Pending bookings (awaiting payment)
(7, 'hotel_001', 'Grand Plaza Hotel', '2024-12-20', '2024-12-23', 1, 2, 0, 750.00, 'PENDING', 'PENDING'),
(8, 'hotel_002', 'Seaside Resort', '2024-12-25', '2024-12-30', 2, 4, 2, 1750.00, 'PENDING', 'PENDING'),
(2, 'hotel_008', 'Historic Downtown Inn', '2025-01-05', '2025-01-08', 1, 2, 0, 660.00, 'PENDING', 'PENDING'),

-- Future bookings for next year
(3, 'hotel_009', 'Waterfront Resort', '2025-02-14', '2025-02-17', 1, 2, 0, 960.00, 'CONFIRMED', 'SUCCESS'),
(4, 'hotel_010', 'Desert Oasis Resort', '2025-03-15', '2025-03-20', 2, 4, 1, 1900.00, 'CONFIRMED', 'SUCCESS'),
(5, 'hotel_006', 'Luxury Resort & Spa', '2025-04-10', '2025-04-15', 1, 2, 0, 2250.00, 'PENDING', 'PENDING'),

-- Weekend getaways
(6, 'hotel_003', 'Mountain View Lodge', '2024-11-16', '2024-11-17', 1, 2, 0, 180.00, 'CONFIRMED', 'SUCCESS'),
(7, 'hotel_005', 'City Center Hotel', '2024-11-23', '2024-11-24', 1, 2, 0, 280.00, 'CONFIRMED', 'SUCCESS'),
(8, 'hotel_011', 'Riverside Lodge', '2024-11-30', '2024-12-01', 1, 2, 0, 190.00, 'PENDING', 'PENDING'),

-- Business travel bookings
(1, 'hotel_004', 'Downtown Business Hotel', '2024-11-14', '2024-11-15', 1, 1, 0, 200.00, 'CONFIRMED', 'SUCCESS'),
(2, 'hotel_012', 'Metropolitan Suites', '2024-11-21', '2024-11-22', 1, 1, 0, 240.00, 'CONFIRMED', 'SUCCESS'),
(3, 'hotel_007', 'Airport Hotel', '2024-12-03', '2024-12-04', 1, 1, 0, 120.00, 'PENDING', 'PENDING'),

-- Family vacation bookings
(4, 'hotel_002', 'Seaside Resort', '2025-06-15', '2025-06-22', 3, 6, 4, 7350.00, 'CONFIRMED', 'SUCCESS'),
(5, 'hotel_010', 'Desert Oasis Resort', '2025-07-04', '2025-07-11', 2, 4, 2, 2660.00, 'PENDING', 'PENDING'),
(6, 'hotel_009', 'Waterfront Resort', '2025-08-10', '2025-08-17', 2, 4, 2, 4480.00, 'CONFIRMED', 'SUCCESS'),

-- Cancelled bookings (for testing cancellation flow)
(7, 'hotel_001', 'Grand Plaza Hotel', '2024-10-20', '2024-10-23', 1, 2, 0, 750.00, 'CANCELLED', 'REFUNDED'),
(8, 'hotel_005', 'City Center Hotel', '2024-10-25', '2024-10-28', 1, 2, 0, 840.00, 'CANCELLED', 'REFUNDED'),

-- Last-minute bookings
(1, 'hotel_007', 'Airport Hotel', CURRENT_DATE + INTERVAL '2 days', CURRENT_DATE + INTERVAL '3 days', 1, 1, 0, 120.00, 'PENDING', 'PENDING'),
(2, 'hotel_004', 'Downtown Business Hotel', CURRENT_DATE + INTERVAL '5 days', CURRENT_DATE + INTERVAL '7 days', 1, 2, 0, 400.00, 'CONFIRMED', 'SUCCESS')

ON CONFLICT DO NOTHING;

-- Update timestamps for realistic data
UPDATE bookings SET 
    created_at = CASE 
        WHEN status = 'COMPLETED' THEN created_at - INTERVAL '30 days'
        WHEN status = 'CANCELLED' THEN created_at - INTERVAL '15 days'
        ELSE created_at
    END,
    updated_at = CASE
        WHEN status = 'COMPLETED' THEN updated_at - INTERVAL '25 days'
        WHEN status = 'CANCELLED' THEN updated_at - INTERVAL '10 days'
        ELSE updated_at
    END
WHERE id > 10;

-- Payment status is already set in the INSERT statements above

-- Add transaction IDs for completed payments
UPDATE bookings SET transaction_id = 'TXN_' || id || '_' || extract(epoch from created_at)::text 
WHERE payment_status IN ('COMPLETED', 'REFUNDED');

-- Create some booking statistics views (for admin dashboard)
-- Note: These are just for reference, actual views would be created by the application

-- Summary statistics
-- SELECT 
--     COUNT(*) as total_bookings,
--     COUNT(CASE WHEN status = 'CONFIRMED' THEN 1 END) as confirmed_bookings,
--     COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_bookings,
--     COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_bookings,
--     COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled_bookings,
--     SUM(total_price) as total_revenue,
--     AVG(total_price) as average_booking_value
-- FROM bookings;

-- Monthly booking trends
-- SELECT 
--     DATE_TRUNC('month', check_in_date) as month,
--     COUNT(*) as bookings_count,
--     SUM(total_price) as monthly_revenue
-- FROM bookings 
-- WHERE status != 'CANCELLED'
-- GROUP BY DATE_TRUNC('month', check_in_date)
-- ORDER BY month;

-- Popular hotels
-- SELECT 
--     hotel_name,
--     COUNT(*) as booking_count,
--     SUM(total_price) as total_revenue,
--     AVG(total_price) as avg_booking_value
-- FROM bookings 
-- WHERE status != 'CANCELLED'
-- GROUP BY hotel_name
-- ORDER BY booking_count DESC;
