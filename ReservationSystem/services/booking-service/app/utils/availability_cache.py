"""
Booking Availability Cache Module
Handles room availability caching in Redis for faster lookups
"""

import redis.asyncio as redis
import os
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, List

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

redis_client = None

async def get_redis():
    """Get Redis client instance"""
    global redis_client
    if redis_client is None:
        redis_client = await redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    return redis_client

async def get_availability_cache_key(hotel_id: str, check_in: str, check_out: str) -> str:
    """Generate cache key for room availability"""
    return f"availability:{hotel_id}:{check_in}:{check_out}"

async def get_room_availability(hotel_id: str, check_in: str, check_out: str) -> Optional[Dict]:
    """
    Get room availability from cache
    Returns: Dict with availability data or None if not cached
    """
    try:
        client = await get_redis()
        cache_key = await get_availability_cache_key(hotel_id, check_in, check_out)
        
        cached_data = await client.get(cache_key)
        if cached_data:
            print(f"✅ Cache HIT for availability: {cache_key}")
            return json.loads(cached_data)
        
        print(f"❌ Cache MISS for availability: {cache_key}")
        return None
    except Exception as e:
        print(f"⚠️  Redis availability cache get error: {e}")
        return None

async def set_room_availability(
    hotel_id: str, 
    check_in: str, 
    check_out: str, 
    availability_data: Dict,
    ttl: int = 300  # 5 minutes default
) -> bool:
    """
    Cache room availability data
    Args:
        hotel_id: Hotel ID
        check_in: Check-in date (YYYY-MM-DD)
        check_out: Check-out date (YYYY-MM-DD)
        availability_data: Dict containing availability info
        ttl: Time to live in seconds (default: 5 minutes)
    Returns: True if successful, False otherwise
    """
    try:
        client = await get_redis()
        cache_key = await get_availability_cache_key(hotel_id, check_in, check_out)
        
        await client.set(cache_key, json.dumps(availability_data), ex=ttl)
        print(f"✅ Cached availability: {cache_key} (TTL: {ttl}s)")
        return True
    except Exception as e:
        print(f"⚠️  Redis availability cache set error: {e}")
        return False

async def invalidate_availability_cache(hotel_id: str, check_in: str, check_out: str) -> bool:
    """
    Invalidate availability cache for specific dates
    Called when a booking is created or cancelled
    """
    try:
        client = await get_redis()
        cache_key = await get_availability_cache_key(hotel_id, check_in, check_out)
        
        await client.delete(cache_key)
        print(f"🗑️  Invalidated availability cache: {cache_key}")
        return True
    except Exception as e:
        print(f"⚠️  Redis availability cache delete error: {e}")
        return False

async def invalidate_hotel_availability(hotel_id: str) -> int:
    """
    Invalidate all availability cache entries for a hotel
    Returns: Number of keys deleted
    """
    try:
        client = await get_redis()
        pattern = f"availability:{hotel_id}:*"
        
        # Find all matching keys
        keys = []
        async for key in client.scan_iter(match=pattern):
            keys.append(key)
        
        if keys:
            deleted = await client.delete(*keys)
            print(f"🗑️  Invalidated {deleted} availability cache entries for hotel {hotel_id}")
            return deleted
        
        return 0
    except Exception as e:
        print(f"⚠️  Redis availability cache bulk delete error: {e}")
        return 0

async def check_room_availability_with_cache(
    hotel_id: str,
    check_in: str,
    check_out: str,
    rooms_needed: int,
    db_connection
) -> Dict:
    """
    Check room availability with Redis caching
    First checks cache, then falls back to database if needed
    
    Args:
        hotel_id: Hotel ID
        check_in: Check-in date
        check_out: Check-out date
        rooms_needed: Number of rooms needed
        db_connection: Database connection for fallback
    
    Returns:
        Dict with availability status and details
    """
    # Try cache first
    cached = await get_room_availability(hotel_id, check_in, check_out)
    if cached:
        cached['from_cache'] = True
        return cached
    
    # Cache miss - query database
    try:
        # Query bookings that overlap with requested dates
        query = """
            SELECT COUNT(*) as booked_rooms
            FROM bookings
            WHERE hotel_id = $1
            AND status NOT IN ('CANCELLED', 'FAILED')
            AND (
                (check_in_date <= $2 AND check_out_date > $2) OR
                (check_in_date < $3 AND check_out_date >= $3) OR
                (check_in_date >= $2 AND check_out_date <= $3)
            )
        """
        
        result = await db_connection.fetchrow(query, hotel_id, check_in, check_out)
        booked_rooms = result['booked_rooms'] if result else 0
        
        # Assume hotel has 100 rooms (this should come from hotel service in production)
        total_rooms = 100
        available_rooms = total_rooms - booked_rooms
        
        availability_data = {
            'hotel_id': hotel_id,
            'check_in': check_in,
            'check_out': check_out,
            'total_rooms': total_rooms,
            'booked_rooms': booked_rooms,
            'available_rooms': available_rooms,
            'is_available': available_rooms >= rooms_needed,
            'rooms_needed': rooms_needed,
            'from_cache': False,
            'cached_at': datetime.utcnow().isoformat()
        }
        
        # Cache the result
        await set_room_availability(hotel_id, check_in, check_out, availability_data, ttl=300)
        
        return availability_data
        
    except Exception as e:
        print(f"❌ Error checking room availability: {e}")
        return {
            'hotel_id': hotel_id,
            'is_available': False,
            'error': str(e),
            'from_cache': False
        }

async def get_availability_stats() -> Dict:
    """
    Get statistics about availability cache
    Returns cache hit/miss metrics
    """
    try:
        client = await get_redis()
        
        # Count availability cache keys
        pattern = "availability:*"
        count = 0
        async for _ in client.scan_iter(match=pattern):
            count += 1
        
        return {
            'total_cached_availabilities': count,
            'cache_pattern': pattern,
            'ttl_seconds': 300
        }
    except Exception as e:
        print(f"⚠️  Error getting availability stats: {e}")
        return {'error': str(e)}

