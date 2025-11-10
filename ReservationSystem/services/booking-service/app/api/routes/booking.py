from fastapi import APIRouter, HTTPException, Header, Depends, Request
from typing import List, Optional, Union
from datetime import datetime, date
from pydantic import BaseModel, ValidationError, validator
import asyncpg
import os
import json
import logging
from kafka import KafkaProducer
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
from app.utils.availability_cache import (
    check_room_availability_with_cache,
    invalidate_availability_cache,
    get_availability_stats
)
from app.utils.cache import get_cache

logger = logging.getLogger(__name__)

router = APIRouter()

# Kafka Producer (optional - will try to connect but won't fail if unavailable)
kafka_producer = None

def get_kafka_producer():
    global kafka_producer
    if kafka_producer is None:
        try:
            kafka_producer = KafkaProducer(
                bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9093'),
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                request_timeout_ms=5000,
                max_block_ms=5000
            )
            print("✅ Connected to Kafka")
        except Exception as e:
            print(f"⚠️  Kafka not available: {e}")
            kafka_producer = None
    return kafka_producer

def publish_event(topic: str, event: dict):
    """Publish event to Kafka (optional - won't fail if Kafka unavailable)"""
    import time
    from app.metrics import record_kafka_message

    start_time = time.time()
    try:
        producer = get_kafka_producer()
        if producer:
            producer.send(topic, event)
            duration = time.time() - start_time
            record_kafka_message(topic=topic, status='sent', duration=duration)
            print(f"📨 Published event to Kafka: {event.get('eventType')}")
    except Exception as e:
        duration = time.time() - start_time
        record_kafka_message(topic=topic, status='failed', duration=duration)
        print(f"⚠️  Failed to publish to Kafka: {e}")

# Database connection - Isolated Booking Database
async def get_db_connection():
    """Create a new database connection with timeout"""
    try:
        conn = await asyncpg.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', '5433')),
            user=os.getenv('DB_USER', 'booking_user'),
            password=os.getenv('DB_PASSWORD', 'booking_pass'),
            database=os.getenv('DB_NAME', 'booking_db'),
            timeout=5.0,
            command_timeout=5.0,
            ssl=False
        )
        return conn
    except Exception as e:
        logger.error(f"❌ Failed to connect to database: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")

# Models
class BookingCreate(BaseModel):
    userId: Union[str, int]
    hotelId: str
    hotelName: str
    checkInDate: str
    checkOutDate: str
    rooms: int
    adults: int
    children: int
    totalPrice: Union[float, int]

    @validator('userId', pre=True)
    def convert_user_id_to_str(cls, v):
        return str(v)

    @validator('totalPrice', pre=True)
    def convert_price_to_float(cls, v):
        return float(v)

class BookingConfirm(BaseModel):
    paymentId: str
    transactionId: str

class BookingResponse(BaseModel):
    id: str
    userId: str
    hotelId: str
    hotelName: str
    checkInDate: str
    checkOutDate: str
    rooms: int
    adults: int
    children: int
    totalPrice: float
    status: str
    paymentStatus: Optional[str] = None
    paymentId: Optional[str] = None
    transactionId: Optional[str] = None
    createdAt: str
    updatedAt: str

@router.get("/availability/check")
async def check_availability(
    hotel_id: str,
    check_in: str,
    check_out: str,
    rooms: int = 1
):
    """
    Check room availability for a hotel with Redis caching
    Returns availability status and details
    """
    conn = await get_db_connection()
    try:
        availability = await check_room_availability_with_cache(
            hotel_id=hotel_id,
            check_in=check_in,
            check_out=check_out,
            rooms_needed=rooms,
            db_connection=conn
        )
        return availability
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error checking availability: {str(e)}")
    finally:
        await conn.close()

@router.get("/availability/stats")
async def get_cache_stats():
    """Get availability cache statistics"""
    try:
        stats = await get_availability_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting stats: {str(e)}")

@router.get("/", response_model=List[BookingResponse])
async def get_user_bookings(
    request: Request,
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
    x_user_role: Optional[str] = Header(None, alias="X-User-Role")
):
    """Get bookings - filtered by user for regular users, all bookings for admins"""

    if not x_user_id:
        raise HTTPException(status_code=401, detail="User ID not provided")

    conn = None
    try:
        logger.info(f"📨 Fetching bookings for user: {x_user_id}")

        # Try cache first
        cache = get_cache()
        if cache:
            cache_key = f"bookings:user:{x_user_id}" if x_user_role != 'ADMIN' else "bookings:all"
            cached_data = cache.get(cache_key)
            if cached_data:
                logger.info(f"✅ [BOOKINGS] Cache hit for key: {cache_key}")
                return cached_data
            logger.info(f"⚠️  [BOOKINGS] Cache miss for key: {cache_key}")

        conn = await get_db_connection()
        logger.info(f"✅ Connected to database")

        # Admin can see all bookings, regular users only see their own
        if x_user_role == 'ADMIN':
            logger.info("🔍 Fetching all bookings (admin)")
            rows = await conn.fetch('''
                SELECT id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                       rooms, adults, children, total_price, status, payment_status,
                       payment_id, transaction_id, created_at, updated_at
                FROM bookings
                ORDER BY created_at DESC
            ''')
        else:
            logger.info(f"🔍 Fetching bookings for user {x_user_id}")
            rows = await conn.fetch('''
                SELECT id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                       rooms, adults, children, total_price, status, payment_status,
                       payment_id, transaction_id, created_at, updated_at
                FROM bookings
                WHERE user_id = $1
                ORDER BY created_at DESC
            ''', int(x_user_id))

        logger.info(f"✅ Found {len(rows)} bookings")
        bookings = []
        for row in rows:
            bookings.append({
                "id": str(row['id']),
                "userId": str(row['user_id']),
                "hotelId": str(row['hotel_id']),
                "hotelName": row['hotel_name'],
                "checkInDate": row['check_in_date'].isoformat(),
                "checkOutDate": row['check_out_date'].isoformat(),
                "rooms": row['rooms'],
                "adults": row['adults'],
                "children": row['children'],
                "totalPrice": float(row['total_price']),
                "status": row['status'],
                "paymentStatus": row['payment_status'],
                "paymentId": str(row['payment_id']) if row['payment_id'] else None,
                "transactionId": row['transaction_id'],
                "createdAt": row['created_at'].isoformat(),
                "updatedAt": row['updated_at'].isoformat()
            })

        # Cache the result (30 minutes TTL)
        if cache:
            cache_key = f"bookings:user:{x_user_id}" if x_user_role != 'ADMIN' else "bookings:all"
            cache.set(cache_key, bookings, ttl=1800)
            logger.info(f"✅ [BOOKINGS] Cached with key: {cache_key}")

        logger.info(f"✅ Returning {len(bookings)} bookings")
        return bookings
    except Exception as e:
        logger.error(f"❌ Error fetching bookings: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error fetching bookings: {str(e)}")
    finally:
        if conn:
            try:
                await conn.close()
                logger.info("✅ Connection closed")
            except Exception as e:
                logger.error(f"❌ Error closing connection: {e}")

@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking(
    booking_id: str,
    request: Request,
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
    x_user_role: Optional[str] = Header(None, alias="X-User-Role")
):
    """Get a specific booking - verify ownership unless admin"""

    if not x_user_id:
        raise HTTPException(status_code=401, detail="User ID not provided")

    # Try cache first
    cache = get_cache()
    cache_key = f"booking:{booking_id}"
    if cache:
        cached_data = cache.get(cache_key)
        if cached_data:
            # Verify ownership from cached data
            if x_user_role != 'ADMIN' and str(cached_data.get('userId')) != x_user_id:
                raise HTTPException(status_code=403, detail="Access denied - not your booking")
            logger.info(f"✅ [BOOKING DETAILS] Cache hit for booking ID: {booking_id}")
            return cached_data
        logger.info(f"⚠️  [BOOKING DETAILS] Cache miss for booking ID: {booking_id}")

    conn = await get_db_connection()
    try:
        row = await conn.fetchrow('''
            SELECT id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                   rooms, adults, children, total_price, status, payment_status,
                   payment_id, transaction_id, created_at, updated_at
            FROM bookings
            WHERE id = $1
        ''', int(booking_id))

        if not row:
            raise HTTPException(status_code=404, detail="Booking not found")

        # Verify ownership unless admin
        if x_user_role != 'ADMIN' and str(row['user_id']) != x_user_id:
            raise HTTPException(status_code=403, detail="Access denied - not your booking")

        booking_data = {
            "id": str(row['id']),
            "userId": str(row['user_id']),
            "hotelId": str(row['hotel_id']),
            "hotelName": row['hotel_name'],
            "checkInDate": row['check_in_date'].isoformat(),
            "checkOutDate": row['check_out_date'].isoformat(),
            "rooms": row['rooms'],
            "adults": row['adults'],
            "children": row['children'],
            "totalPrice": float(row['total_price']),
            "status": row['status'],
            "paymentStatus": row['payment_status'],
            "paymentId": str(row['payment_id']) if row['payment_id'] else None,
            "transactionId": row['transaction_id'],
            "createdAt": row['created_at'].isoformat(),
            "updatedAt": row['updated_at'].isoformat()
        }

        # Cache the result (1 hour TTL)
        if cache:
            cache.set(cache_key, booking_data, ttl=3600)
            logger.info(f"✅ [BOOKING DETAILS] Cached booking with key: {cache_key}")

        return booking_data
    finally:
        await conn.close()

@router.post("/debug", status_code=200)
async def debug_booking(request: Request):
    """Debug endpoint to see raw request data"""
    body = await request.json()
    print(f"🔍 DEBUG - Raw request body: {json.dumps(body, indent=2)}")
    print(f"🔍 DEBUG - Body type: {type(body)}")
    for key, value in body.items():
        print(f"  {key}: {value} (type: {type(value).__name__})")
    return {"received": body}

@router.post("/", response_model=BookingResponse, status_code=201)
async def create_booking(booking: BookingCreate):
    """Create a new booking with PENDING status"""
    print(f"📥 Received booking request: {booking.dict()}")
    conn = await get_db_connection()
    try:
        # Parse dates
        check_in = datetime.fromisoformat(booking.checkInDate).date()
        check_out = datetime.fromisoformat(booking.checkOutDate).date()

        # Insert booking
        row = await conn.fetchrow('''
            INSERT INTO bookings (
                user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                rooms, adults, children, total_price, status, payment_status,
                created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
            RETURNING id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                      rooms, adults, children, total_price, status, payment_status,
                      payment_id, transaction_id, created_at, updated_at
        ''', int(booking.userId), booking.hotelId, booking.hotelName,
             check_in, check_out, booking.rooms,
             booking.adults, booking.children, booking.totalPrice,
             'PENDING', 'PENDING')

        new_booking = {
            "id": str(row['id']),
            "userId": str(row['user_id']),
            "hotelId": str(row['hotel_id']),
            "hotelName": row['hotel_name'],
            "checkInDate": row['check_in_date'].isoformat(),
            "checkOutDate": row['check_out_date'].isoformat(),
            "rooms": row['rooms'],
            "adults": row['adults'],
            "children": row['children'],
            "totalPrice": float(row['total_price']),
            "status": row['status'],
            "paymentStatus": row['payment_status'],
            "paymentId": None,
            "transactionId": None,
            "createdAt": row['created_at'].isoformat(),
            "updatedAt": row['updated_at'].isoformat()
        }

        # Invalidate availability cache for this hotel and dates
        await invalidate_availability_cache(
            booking.hotelId,
            booking.checkInDate,
            booking.checkOutDate
        )

        # Publish to Kafka (optional)
        publish_event('booking-events', {
            'eventType': 'BOOKING_CREATED',
            'data': {
                'bookingId': new_booking['id'],
                'userId': new_booking['userId'],
                'hotelId': new_booking['hotelId'],
                'hotelName': new_booking['hotelName'],
                'checkInDate': new_booking['checkInDate'],
                'checkOutDate': new_booking['checkOutDate'],
                'rooms': new_booking['rooms'],
                'totalPrice': new_booking['totalPrice']
            },
            'timestamp': datetime.now().isoformat()
        })

        return new_booking
    finally:
        await conn.close()

@router.put("/{booking_id}/confirm", response_model=BookingResponse)
async def confirm_booking(booking_id: str, confirm_data: BookingConfirm):
    """Confirm booking after successful payment"""
    conn = await get_db_connection()
    try:
        # Update booking status
        row = await conn.fetchrow('''
            UPDATE bookings
            SET status = 'CONFIRMED',
                payment_status = 'COMPLETED',
                payment_id = $1,
                transaction_id = $2,
                updated_at = NOW()
            WHERE id = $3
            RETURNING id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                      rooms, adults, children, total_price, status, payment_status,
                      payment_id, transaction_id, created_at, updated_at
        ''', int(confirm_data.paymentId), confirm_data.transactionId, int(booking_id))

        if not row:
            raise HTTPException(status_code=404, detail="Booking not found")

        confirmed_booking = {
            "id": str(row['id']),
            "userId": str(row['user_id']),
            "hotelId": str(row['hotel_id']),
            "hotelName": row['hotel_name'],
            "checkInDate": row['check_in_date'].isoformat(),
            "checkOutDate": row['check_out_date'].isoformat(),
            "rooms": row['rooms'],
            "adults": row['adults'],
            "children": row['children'],
            "totalPrice": float(row['total_price']),
            "status": row['status'],
            "paymentStatus": row['payment_status'],
            "paymentId": str(row['payment_id']),
            "transactionId": row['transaction_id'],
            "createdAt": row['created_at'].isoformat(),
            "updatedAt": row['updated_at'].isoformat()
        }

        # Invalidate cache for this booking
        cache = get_cache()
        if cache:
            cache.delete(f"booking:{booking_id}")
            cache.delete(f"bookings:user:{confirmed_booking['userId']}")
            cache.delete("bookings:all")
            logger.info(f"✅ [BOOKING CONFIRM] Cache invalidated for booking {booking_id}")

        # Publish to Kafka (optional)
        publish_event('booking-events', {
            'eventType': 'BOOKING_CONFIRMED',
            'data': {
                'bookingId': confirmed_booking['id'],
                'userId': confirmed_booking['userId'],
                'hotelId': confirmed_booking['hotelId'],
                'paymentId': confirmed_booking['paymentId'],
                'transactionId': confirmed_booking['transactionId']
            },
            'timestamp': datetime.now().isoformat()
        })

        return confirmed_booking
    finally:
        await conn.close()

@router.put("/{booking_id}/cancel", response_model=BookingResponse)
async def cancel_booking(
    booking_id: str,
    request: Request,
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
    x_user_role: Optional[str] = Header(None, alias="X-User-Role")
):
    """Cancel a booking - verify ownership unless admin"""

    if not x_user_id:
        raise HTTPException(status_code=401, detail="User ID not provided")

    conn = await get_db_connection()
    try:
        # First check if booking exists and user owns it
        existing = await conn.fetchrow('SELECT user_id FROM bookings WHERE id = $1', int(booking_id))

        if not existing:
            raise HTTPException(status_code=404, detail="Booking not found")

        # Verify ownership unless admin
        if x_user_role != 'ADMIN' and str(existing['user_id']) != x_user_id:
            raise HTTPException(status_code=403, detail="Access denied - not your booking")

        # Update booking status
        row = await conn.fetchrow('''
            UPDATE bookings
            SET status = 'CANCELLED',
                updated_at = NOW()
            WHERE id = $1
            RETURNING id, user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                      rooms, adults, children, total_price, status, payment_status,
                      payment_id, transaction_id, created_at, updated_at
        ''', int(booking_id))

        if not row:
            raise HTTPException(status_code=404, detail="Booking not found")

        cancelled_booking = {
            "id": str(row['id']),
            "userId": str(row['user_id']),
            "hotelId": str(row['hotel_id']),
            "hotelName": row['hotel_name'],
            "checkInDate": row['check_in_date'].isoformat(),
            "checkOutDate": row['check_out_date'].isoformat(),
            "rooms": row['rooms'],
            "adults": row['adults'],
            "children": row['children'],
            "totalPrice": float(row['total_price']),
            "status": row['status'],
            "paymentStatus": row['payment_status'],
            "paymentId": str(row['payment_id']) if row['payment_id'] else None,
            "transactionId": row['transaction_id'],
            "createdAt": row['created_at'].isoformat(),
            "updatedAt": row['updated_at'].isoformat()
        }

        # Invalidate availability cache for this hotel and dates
        await invalidate_availability_cache(
            cancelled_booking['hotelId'],
            cancelled_booking['checkInDate'],
            cancelled_booking['checkOutDate']
        )

        # Publish to Kafka (optional)
        publish_event('booking-events', {
            'eventType': 'BOOKING_CANCELLED',
            'bookingId': cancelled_booking['id'],
            'userId': cancelled_booking['userId'],
            'hotelId': cancelled_booking['hotelId'],
            'timestamp': datetime.now().isoformat()
        })

        return cancelled_booking
    finally:
        await conn.close()

