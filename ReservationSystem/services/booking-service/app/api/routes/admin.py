from fastapi import APIRouter, HTTPException, Header
from typing import Optional, List
import asyncpg
import os
from datetime import datetime
from app.utils.cache import get_cache


router = APIRouter()

# Database connection
async def get_db_connection():
    return await asyncpg.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=int(os.getenv('DB_PORT', '5432')),
        user=os.getenv('DB_USER', 'admin'),
        password=os.getenv('DB_PASSWORD', 'admin'),
        database=os.getenv('DB_NAME', 'hotel_db')
    )

@router.get("/bookings")
async def get_all_bookings(
    status: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
    x_user_role: Optional[str] = Header(None, alias="X-User-Role")
):
    """
    Get all bookings (admin only)
    Query params:
    - status: Filter by booking status (PENDING, CONFIRMED, CANCELLED, COMPLETED)
    - limit: Number of records to return (default: 100)
    - offset: Number of records to skip (default: 0)
    """
    
    # In production, verify admin role from JWT
    # if x_user_role != "ADMIN":
    #     raise HTTPException(status_code=403, detail="Admin access required")
    
    conn = await get_db_connection()
    try:
        query = '''
            SELECT id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                   rooms, adults, children, total_price, status, payment_status,
                   payment_id, transaction_id, created_at, updated_at
            FROM bookings
        '''
        params = []
        
        if status:
            query += ' WHERE status = $1'
            params.append(status.upper())
            query += ' ORDER BY created_at DESC LIMIT $2 OFFSET $3'
            params.extend([limit, offset])
        else:
            query += ' ORDER BY created_at DESC LIMIT $1 OFFSET $2'
            params.extend([limit, offset])
        
        rows = await conn.fetch(query, *params)
        
        bookings = []
        for row in rows:
            bookings.append({
                'id': str(row['id']),
                'userId': str(row['user_id']),
                'hotelId': row['hotel_id'],
                'hotelName': row['hotel_name'],
                'checkInDate': row['check_in_date'].isoformat(),
                'checkOutDate': row['check_out_date'].isoformat(),
                'rooms': row['rooms'],
                'adults': row['adults'],
                'children': row['children'],
                'totalPrice': float(row['total_price']),
                'status': row['status'],
                'paymentStatus': row['payment_status'],
                'paymentId': str(row['payment_id']) if row['payment_id'] else None,
                'transactionId': row['transaction_id'],
                'createdAt': row['created_at'].isoformat(),
                'updatedAt': row['updated_at'].isoformat()
            })
        
        return {
            'bookings': bookings,
            'total': len(bookings),
            'limit': limit,
            'offset': offset
        }
    finally:
        await conn.close()

@router.get("/bookings/count")
async def get_bookings_count(
    x_user_role: Optional[str] = Header(None, alias="X-User-Role")
):
    """
    Get booking counts by status (admin only)
    """
    
    # In production, verify admin role from JWT
    # if x_user_role != "ADMIN":
    #     raise HTTPException(status_code=403, detail="Admin access required")
    
    conn = await get_db_connection()
    try:
        # Total count
        total_row = await conn.fetchrow('SELECT COUNT(*) as count FROM bookings')
        total = total_row['count']
        
        # Count by status
        pending_row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM bookings WHERE status = 'PENDING'"
        )
        confirmed_row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM bookings WHERE status = 'CONFIRMED'"
        )
        cancelled_row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM bookings WHERE status = 'CANCELLED'"
        )
        completed_row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM bookings WHERE status = 'COMPLETED'"
        )
        
        # Count by payment status
        payment_pending_row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM bookings WHERE payment_status = 'PENDING'"
        )
        payment_completed_row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM bookings WHERE payment_status = 'COMPLETED'"
        )
        payment_failed_row = await conn.fetchrow(
            "SELECT COUNT(*) as count FROM bookings WHERE payment_status = 'FAILED'"
        )
        
        return {
            'total': total,
            'byStatus': {
                'pending': pending_row['count'],
                'confirmed': confirmed_row['count'],
                'cancelled': cancelled_row['count'],
                'completed': completed_row['count']
            },
            'byPaymentStatus': {
                'pending': payment_pending_row['count'],
                'completed': payment_completed_row['count'],
                'failed': payment_failed_row['count']
            }
        }
    finally:
        await conn.close()

@router.get("/bookings/stats")
async def get_bookings_stats(
    x_user_role: Optional[str] = Header(None, alias="X-User-Role")
):
    """
    Get booking statistics (admin only)
    """
    
    # In production, verify admin role from JWT
    # if x_user_role != "ADMIN":
    #     raise HTTPException(status_code=403, detail="Admin access required")
    
    conn = await get_db_connection()
    try:
        # Total revenue
        revenue_row = await conn.fetchrow(
            "SELECT SUM(total_price) as revenue FROM bookings WHERE status != 'CANCELLED'"
        )
        total_revenue = float(revenue_row['revenue']) if revenue_row['revenue'] else 0.0
        
        # Revenue by status
        confirmed_revenue_row = await conn.fetchrow(
            "SELECT SUM(total_price) as revenue FROM bookings WHERE status = 'CONFIRMED'"
        )
        confirmed_revenue = float(confirmed_revenue_row['revenue']) if confirmed_revenue_row['revenue'] else 0.0
        
        # Average booking value
        avg_row = await conn.fetchrow(
            "SELECT AVG(total_price) as avg FROM bookings WHERE status != 'CANCELLED'"
        )
        avg_booking_value = float(avg_row['avg']) if avg_row['avg'] else 0.0
        
        # Total rooms booked
        rooms_row = await conn.fetchrow(
            "SELECT SUM(rooms) as total FROM bookings WHERE status != 'CANCELLED'"
        )
        total_rooms = rooms_row['total'] if rooms_row['total'] else 0
        
        # Total guests
        guests_row = await conn.fetchrow(
            "SELECT SUM(adults + children) as total FROM bookings WHERE status != 'CANCELLED'"
        )
        total_guests = guests_row['total'] if guests_row['total'] else 0
        
        # Top hotels by bookings
        top_hotels = await conn.fetch('''
            SELECT hotel_name, COUNT(*) as booking_count, SUM(total_price) as revenue
            FROM bookings
            WHERE status != 'CANCELLED'
            GROUP BY hotel_name
            ORDER BY booking_count DESC
            LIMIT 5
        ''')
        
        return {
            'totalRevenue': total_revenue,
            'confirmedRevenue': confirmed_revenue,
            'averageBookingValue': avg_booking_value,
            'totalRoomsBooked': total_rooms,
            'totalGuests': total_guests,
            'topHotels': [
                {
                    'hotelName': row['hotel_name'],
                    'bookingCount': row['booking_count'],
                    'revenue': float(row['revenue'])
                }
                for row in top_hotels
            ]
        }
    finally:
        await conn.close()

@router.get("/bookings/recent")
async def get_recent_bookings(
    limit: int = 10,
    x_user_role: Optional[str] = Header(None, alias="X-User-Role")
):
    """
    Get recent bookings (admin only)
    """
    
    # In production, verify admin role from JWT
    # if x_user_role != "ADMIN":
    #     raise HTTPException(status_code=403, detail="Admin access required")
    
    conn = await get_db_connection()
    try:
        rows = await conn.fetch('''
            SELECT id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                   rooms, adults, children, total_price, status, payment_status,
                   created_at, updated_at
            FROM bookings
            ORDER BY created_at DESC
            LIMIT $1
        ''', limit)
        
        bookings = []
        for row in rows:
            bookings.append({
                'id': str(row['id']),
                'userId': str(row['user_id']),
                'hotelId': row['hotel_id'],
                'hotelName': row['hotel_name'],
                'checkInDate': row['check_in_date'].isoformat(),
                'checkOutDate': row['check_out_date'].isoformat(),
                'rooms': row['rooms'],
                'adults': row['adults'],
                'children': row['children'],
                'totalPrice': float(row['total_price']),
                'status': row['status'],
                'paymentStatus': row['payment_status'],
                'createdAt': row['created_at'].isoformat(),
                'updatedAt': row['updated_at'].isoformat()
            })
        
        return {
            'bookings': bookings,
            'count': len(bookings)
        }
    finally:
        await conn.close()

# Cache Management Endpoints
@router.get("/cache/stats")
async def get_cache_stats():
    """Get cache statistics"""
    cache = get_cache()
    if not cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    return cache.get_stats()

@router.get("/cache/keys")
async def get_cache_keys():
    """Get all cache keys"""
    cache = get_cache()
    if not cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    keys = cache.get_all_keys()
    return {"keys": keys, "count": len(keys)}

@router.post("/cache/flush")
async def flush_cache():
    """Flush all cache"""
    cache = get_cache()
    if not cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    success = cache.flush_all()
    return {"success": success, "message": "Cache flushed" if success else "Failed to flush cache"}

@router.delete("/cache/keys/{key:path}")
async def delete_cache_key(key: str):
    """Delete specific cache key"""
    cache = get_cache()
    if not cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    success = cache.delete(key)
    return {"success": success, "message": f"Key '{key}' deleted" if success else f"Key '{key}' not found"}

@router.get("/cache/print-stats")
async def print_cache_stats():
    """Print cache statistics to console"""
    cache = get_cache()
    if not cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    cache.print_stats()
    return {"message": "Stats printed to console"}


