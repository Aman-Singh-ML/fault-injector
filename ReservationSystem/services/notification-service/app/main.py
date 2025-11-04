from fastapi import FastAPI, Request, Response, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import asyncio
import json
from datetime import datetime
from typing import Dict, List
from collections import defaultdict
import motor.motor_asyncio
import os
import threading
import time
import redis
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from app.tracing import init_tracing
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Initialize tracing
init_tracing("notification-service")

# Prometheus metrics - use try-except to handle re-registration
try:
    http_requests_total = Counter(
        'http_requests_total',
        'Total HTTP requests',
        ['method', 'endpoint', 'status']
    )
except ValueError:
    from prometheus_client import REGISTRY
    http_requests_total = REGISTRY._names_to_collectors.get('http_requests_total')

try:
    http_request_duration_seconds = Histogram(
        'http_request_duration_seconds',
        'HTTP request latency',
        ['method', 'endpoint']
    )
except ValueError:
    from prometheus_client import REGISTRY
    http_request_duration_seconds = REGISTRY._names_to_collectors.get('http_request_duration_seconds')

# Kafka metrics
try:
    kafka_messages_total = Counter(
        'notification_service_kafka_messages_total',
        'Total Kafka messages',
        ['topic', 'status']
    )
except ValueError:
    from prometheus_client import REGISTRY
    kafka_messages_total = REGISTRY._names_to_collectors.get('notification_service_kafka_messages_total')

try:
    kafka_message_duration_seconds = Histogram(
        'notification_service_kafka_message_duration_seconds',
        'Kafka message processing duration in seconds',
        ['topic']
    )
except ValueError:
    from prometheus_client import REGISTRY
    kafka_message_duration_seconds = REGISTRY._names_to_collectors.get('notification_service_kafka_message_duration_seconds')

app = FastAPI(
    title="Notification Service",
    description="Real-time Notification Service with Kafka",
    version="1.0.0"
)

# Instrument FastAPI app
FastAPIInstrumentor.instrument_app(app)

# Prometheus metrics middleware
@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    start_time = time.time()

    response = await call_next(request)

    duration = time.time() - start_time

    # Record metrics
    http_requests_total.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()

    http_request_duration_seconds.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)

    return response

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB connection
MONGO_URI = os.getenv("MONGO_URI", "mongodb://admin:admin@localhost:27017")
mongo_client = motor.motor_asyncio.AsyncIOMotorClient(MONGO_URI)
db = mongo_client.hotel_db
notifications_collection = db.notifications

# Redis connection for notification service (port 6384)
redis_host = os.getenv('REDIS_HOST', 'localhost')
redis_port = int(os.getenv('REDIS_PORT', '6384'))
redis_client = None

# Kafka consumer task
kafka_consumer_task = None

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    print(f"❌ Validation Error: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()},
    )

def consume_kafka_events_sync():
    """Consume events from Kafka and create notifications (runs in separate thread)"""
    from kafka import KafkaConsumer
    import json
    import traceback

    print("🔄 Starting Kafka consumer thread...")

    # Get Kafka configuration from environment variables
    kafka_bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
    kafka_topic = os.getenv("KAFKA_TOPIC_BOOKING_EVENTS", "booking-events")

    print(f"🔗 Connecting to Kafka at: {kafka_bootstrap_servers}")
    print(f"📋 Subscribing to topics: {kafka_topic}, payment-events")

    try:
        consumer = KafkaConsumer(
            kafka_topic,
            'payment-events',
            bootstrap_servers=kafka_bootstrap_servers.split(','),
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            group_id='notification-service',
            auto_offset_reset='earliest',
            enable_auto_commit=True
        )

        print("✅ Connected to Kafka - listening for events...")
        print(f"📋 Subscribed to topics: {consumer.subscription()}")

        for message in consumer:
            topic_name = message.topic
            print(f"📬 Raw Kafka message received from topic: {topic_name}")
            start_time = time.time()
            try:
                event = message.value
                # Support both eventType (camelCase) and event_type (snake_case)
                event_type = event.get('eventType') or event.get('event_type')
                data = event.get('data', {})

                print(f"📨 Received Kafka event: {event_type}")
                print(f"📦 Event data: {data}")
                
                # Create notification based on event type
                notification = None

                if event_type == 'BOOKING_CREATED':
                    # Format: "hotel-name booking is created for n-room, n-adults, n-children, from date x to y for n days, with amount x is successful/pending"
                    hotel_name = data.get('hotelName', 'Hotel')
                    rooms = data.get('rooms', 1)
                    adults = data.get('adults', 1)
                    children = data.get('children', 0)
                    check_in = data.get('checkInDate', '')
                    check_out = data.get('checkOutDate', '')
                    days = data.get('days', 0)
                    amount = data.get('totalPrice', 0)
                    status = data.get('status', 'pending').lower()
                    db_reachable = data.get('dbReachable', True)

                    # Determine status text
                    status_text = "successful" if db_reachable and status in ['confirmed', 'successful'] else "pending"

                    message = f"{hotel_name} booking is created for {rooms} room{'s' if rooms > 1 else ''}, {adults} adult{'s' if adults > 1 else ''}, {children} child{'ren' if children != 1 else ''}, from {check_in} to {check_out} for {days} day{'s' if days > 1 else ''}, with amount ${amount:.2f} is {status_text}"

                    notification = {
                        'userId': str(data.get('userId')),
                        'type': 'booking',
                        'title': 'Booking Created',
                        'message': message,
                        'data': data,
                        'read': False,
                        'createdAt': datetime.utcnow()
                    }

                elif event_type == 'BOOKING_CREATION_STARTED':
                    # Format: "hotel-name booking is queued to book for n-room, n-adults, n-children, from date x to y for n days, with amount x"
                    hotel_name = data.get('hotelName', 'Hotel')
                    rooms = data.get('rooms', 1)
                    adults = data.get('adults', 1)
                    children = data.get('children', 0)
                    check_in = data.get('checkInDate', '')
                    check_out = data.get('checkOutDate', '')
                    days = data.get('days', 0)
                    amount = data.get('totalPrice', 0)

                    message = f"{hotel_name} booking is queued to book for {rooms} room{'s' if rooms > 1 else ''}, {adults} adult{'s' if adults > 1 else ''}, {children} child{'ren' if children != 1 else ''}, from {check_in} to {check_out} for {days} day{'s' if days > 1 else ''}, with amount ${amount:.2f}"

                    notification = {
                        'userId': str(data.get('userId')),
                        'type': 'booking',
                        'title': 'Booking Request Queued',
                        'message': message,
                        'data': data,
                        'read': False,
                        'createdAt': datetime.utcnow()
                    }

                elif event_type == 'BOOKING_CONFIRMED':
                    notification = {
                        'userId': str(data.get('userId')),
                        'type': 'booking',
                        'title': 'Booking Confirmed',
                        'message': f"Your booking #{data.get('bookingId')} has been confirmed!",
                        'data': data,
                        'read': False,
                        'createdAt': datetime.utcnow()
                    }

                elif event_type == 'BOOKING_CANCELLED':
                    notification = {
                        'userId': str(data.get('userId', event.get('userId', 'unknown'))),
                        'type': 'booking',
                        'title': 'Booking Cancelled',
                        'message': f"Your booking #{data.get('bookingId', event.get('bookingId', 'N/A'))} has been cancelled.",
                        'data': data if data else event,
                        'read': False,
                        'createdAt': datetime.utcnow()
                    }

                elif event_type == 'PAYMENT_VERIFIED':
                    notification = {
                        'userId': str(data.get('userId')),
                        'type': 'payment',
                        'title': 'Payment Successful',
                        'message': f"Payment of ${data.get('amount')} has been processed successfully!",
                        'data': data,
                        'read': False,
                        'createdAt': datetime.utcnow()
                    }
                
                if notification:
                    # Save to MongoDB (sync version)
                    import pymongo
                    sync_client = pymongo.MongoClient(MONGO_URI)
                    sync_db = sync_client.hotel_db
                    sync_collection = sync_db.notifications

                    result = sync_collection.insert_one(notification)
                    notification['_id'] = str(result.inserted_id)
                    print(f"✅ Notification saved to MongoDB: {notification['_id']}")

                    # Record successful Kafka message processing
                    duration = time.time() - start_time
                    kafka_messages_total.labels(topic=topic_name, status='received').inc()
                    kafka_message_duration_seconds.labels(topic=topic_name).observe(duration)

            except Exception as e:
                # Record failed Kafka message processing
                duration = time.time() - start_time
                kafka_messages_total.labels(topic=topic_name, status='failed').inc()
                kafka_message_duration_seconds.labels(topic=topic_name).observe(duration)
                print(f"❌ Error processing Kafka message: {e}")
                traceback.print_exc()

    except Exception as e:
        print(f"❌ Kafka consumer error: {e}")
        traceback.print_exc()

@app.on_event("startup")
async def startup_event():
    global kafka_consumer_task, redis_client

    # Initialize Redis cache for notification service (port 6384)
    try:
        redis_client = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)
        redis_client.ping()
        print(f"✅ Connected to Redis at {redis_host}:{redis_port}")
    except Exception as e:
        print(f"⚠️  Warning: Could not connect to Redis: {e}")
        redis_client = None

    # Start Kafka consumer in background thread (not asyncio task)
    kafka_thread = threading.Thread(target=consume_kafka_events_sync, daemon=True)
    kafka_thread.start()
    print("🚀 Notification service started")

@app.on_event("shutdown")
async def shutdown_event():
    if kafka_consumer_task:
        kafka_consumer_task.cancel()

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "notification-service"}

@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/notifications")
async def get_notifications(request: Request):
    """Get all notifications for a user - using request body"""
    try:
        body = await request.json()
        user_id = body.get('userId')

        if not user_id:
            return {'notifications': [], 'unreadCount': 0, 'error': 'userId required'}

        notifications = await notifications_collection.find(
            {'userId': str(user_id)}
        ).sort('createdAt', -1).limit(50).to_list(50)

        # Convert ObjectId to string
        for notif in notifications:
            notif['_id'] = str(notif['_id'])
            notif['createdAt'] = notif['createdAt'].isoformat()

        unread_count = await notifications_collection.count_documents(
            {'userId': str(user_id), 'read': False}
        )

        return {
            'notifications': notifications,
            'unreadCount': unread_count
        }
    except Exception as e:
        print(f"❌ Error fetching notifications: {e}")
        return {'notifications': [], 'unreadCount': 0}

@app.put("/notifications/{notification_id}/read")
async def mark_notification_read(notification_id: str):
    """Mark a notification as read"""
    try:
        from bson import ObjectId
        result = await notifications_collection.update_one(
            {'_id': ObjectId(notification_id)},
            {'$set': {'read': True}}
        )

        return {'success': result.modified_count > 0}
    except Exception as e:
        print(f"❌ Error marking notification as read: {e}")
        import traceback
        traceback.print_exc()
        return {'success': False, 'error': str(e)}

@app.put("/notifications/user/{user_id}/read-all")
async def mark_all_notifications_read(user_id: str):
    """Mark all notifications as read for a user"""
    try:
        result = await notifications_collection.update_many(
            {'userId': user_id, 'read': False},
            {'$set': {'read': True}}
        )

        return {'success': True, 'count': result.modified_count}
    except Exception as e:
        print(f"❌ Error marking all notifications as read: {e}")
        import traceback
        traceback.print_exc()
        return {'success': False, 'error': str(e)}

@app.post("/notifications/read-all")
async def mark_all_notifications_read_post(request: Request):
    """Mark all notifications as read for a user - using request body"""
    try:
        body = await request.json()
        user_id = body.get('userId')

        if not user_id:
            return {'success': False, 'error': 'userId required'}

        result = await notifications_collection.update_many(
            {'userId': str(user_id), 'read': False},
            {'$set': {'read': True}}
        )

        return {'success': True, 'count': result.modified_count}
    except Exception as e:
        print(f"❌ Error marking all notifications as read: {e}")
        import traceback
        traceback.print_exc()
        return {'success': False, 'error': str(e)}

@app.post("/notifications/delete")
async def delete_notification_post(request: Request):
    """Delete a notification - using request body"""
    try:
        from bson import ObjectId
        body = await request.json()
        notification_id = body.get('id')

        if not notification_id:
            return {'success': False, 'error': 'id required'}

        result = await notifications_collection.delete_one(
            {'_id': ObjectId(notification_id)}
        )

        return {'success': result.deleted_count > 0}
    except Exception as e:
        print(f"❌ Error deleting notification: {e}")
        import traceback
        traceback.print_exc()
        return {'success': False, 'error': str(e)}

# ============================================
# ADMIN ENDPOINTS
# ============================================

@app.get("/admin/notifications")
async def get_all_notifications(limit: int = 100, offset: int = 0, notification_type: str = None):
    """Get all notifications (admin only)"""
    try:
        query = {}
        if notification_type:
            query['type'] = notification_type

        notifications = await notifications_collection.find(query).sort(
            'createdAt', -1
        ).skip(offset).limit(limit).to_list(limit)

        # Convert ObjectId to string
        for notif in notifications:
            notif['_id'] = str(notif['_id'])
            notif['createdAt'] = notif['createdAt'].isoformat()

        total = await notifications_collection.count_documents(query)

        return {
            'notifications': notifications,
            'total': total,
            'limit': limit,
            'offset': offset
        }
    except Exception as e:
        print(f"❌ Error fetching all notifications: {e}")
        return {'notifications': [], 'total': 0}

@app.get("/admin/notifications/count")
async def get_notifications_count():
    """Get notification counts (admin only)"""
    try:
        total = await notifications_collection.count_documents({})
        unread = await notifications_collection.count_documents({'read': False})
        read = await notifications_collection.count_documents({'read': True})

        # Count by type
        booking_count = await notifications_collection.count_documents({'type': 'booking'})
        payment_count = await notifications_collection.count_documents({'type': 'payment'})
        user_count = await notifications_collection.count_documents({'type': 'user'})

        return {
            'total': total,
            'unread': unread,
            'read': read,
            'byType': {
                'booking': booking_count,
                'payment': payment_count,
                'user': user_count
            }
        }
    except Exception as e:
        print(f"❌ Error getting notification count: {e}")
        return {'total': 0, 'unread': 0, 'read': 0}

@app.get("/admin/notifications/stats")
async def get_notifications_stats():
    """Get notification statistics (admin only)"""
    try:
        total = await notifications_collection.count_documents({})
        unread = await notifications_collection.count_documents({'read': False})
        read = await notifications_collection.count_documents({'read': True})

        # Count by type
        booking_count = await notifications_collection.count_documents({'type': 'booking'})
        payment_count = await notifications_collection.count_documents({'type': 'payment'})
        user_count = await notifications_collection.count_documents({'type': 'user'})

        # Count unique users
        unique_users = await notifications_collection.distinct('userId')

        # Read rate
        read_rate = (read / total * 100) if total > 0 else 0

        return {
            'total': total,
            'unread': unread,
            'read': read,
            'readRate': round(read_rate, 2),
            'uniqueUsers': len(unique_users),
            'byType': {
                'booking': booking_count,
                'payment': payment_count,
                'user': user_count
            }
        }
    except Exception as e:
        print(f"❌ Error getting notification stats: {e}")
        return {'total': 0, 'unread': 0, 'read': 0}

@app.get("/admin/notifications/recent")
async def get_recent_notifications(limit: int = 10):
    """Get recent notifications (admin only)"""
    try:
        notifications = await notifications_collection.find({}).sort(
            'createdAt', -1
        ).limit(limit).to_list(limit)

        # Convert ObjectId to string
        for notif in notifications:
            notif['_id'] = str(notif['_id'])
            notif['createdAt'] = notif['createdAt'].isoformat()

        return {
            'notifications': notifications,
            'count': len(notifications)
        }
    except Exception as e:
        print(f"❌ Error fetching recent notifications: {e}")
        return {'notifications': [], 'count': 0}

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8083, reload=True)
