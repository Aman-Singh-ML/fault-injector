import json
import asyncio
import asyncpg
import os
from kafka import KafkaConsumer, KafkaProducer
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BookingRequestConsumer:
    def __init__(self):
        self.consumer = None
        self.db_pool = None
        self.running = False
        self.notification_producer = None
        
    async def init_db_pool(self):
        """Initialize database connection pool"""
        try:
            self.db_pool = await asyncpg.create_pool(
                host=os.getenv('DB_HOST', 'localhost'),
                port=int(os.getenv('DB_PORT', '5433')),
                user=os.getenv('DB_USER', 'booking_user'),
                password=os.getenv('DB_PASSWORD', 'booking_pass'),
                database=os.getenv('DB_NAME', 'booking_db'),
                min_size=5,
                max_size=20
            )
            logger.info("✅ Database pool initialized")
        except Exception as e:
            logger.error(f"❌ Failed to initialize database pool: {e}")
            raise
    
    def init_kafka_consumer(self):
        """Initialize Kafka consumer for kafka-booking instance"""
        try:
            # Use kafka-booking instance (port 9094) for booking-requests topic
            kafka_servers = os.getenv('KAFKA_BOOKING_SERVERS', 'localhost:9094').split(',')
            self.consumer = KafkaConsumer(
                'booking-requests',
                bootstrap_servers=kafka_servers,
                group_id='booking-service-group',
                value_deserializer=lambda m: json.loads(m.decode('utf-8')),
                auto_offset_reset='earliest',
                enable_auto_commit=True,
                max_poll_records=100,
                fetch_max_bytes=5*1024,
                session_timeout_ms=10000,
                request_timeout_ms=15000,
                connections_max_idle_ms=30000,
                reconnect_backoff_ms=100,
                reconnect_backoff_max_ms=1000
            )
            logger.info(f"✅ Kafka consumer initialized for topic: booking-requests on kafka-booking instance: {kafka_servers}")

            # Initialize Kafka producer for notifications (general broker)
            notif_servers = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9093').split(',')
            self.notification_producer = KafkaProducer(
                bootstrap_servers=notif_servers,
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                request_timeout_ms=5000,
                max_block_ms=5000
            )
            logger.info(f"✅ Kafka notification producer initialized: {notif_servers}")
        except Exception as e:
            logger.error(f"❌ Failed to initialize Kafka consumer: {e}")
            raise
    
    async def process_booking_request(self, booking_data):
        """Process a booking request from Kafka and publish notification"""
        conn = None
        db_reachable = False
        try:
            # Log the actual booking data to see field names
            logger.info(f"📋 Booking data keys: {booking_data.keys()}")
            logger.info(f"📋 Full booking data: {booking_data}")

            # Create a new connection for this request
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
                db_reachable = True
            except Exception as db_err:
                logger.error(f"❌ Database connection failed: {db_err}")
                db_reachable = False
                # Continue to publish notification even if DB is not reachable

            # Parse dates - use from Kafka if available, otherwise use defaults
            from datetime import timedelta
            if 'checkInDate' in booking_data and booking_data['checkInDate']:
                try:
                    check_in = datetime.strptime(booking_data['checkInDate'], '%Y-%m-%d').date()
                except:
                    check_in = datetime.now().date()
            else:
                check_in = datetime.now().date()

            if 'checkOutDate' in booking_data and booking_data['checkOutDate']:
                try:
                    check_out = datetime.strptime(booking_data['checkOutDate'], '%Y-%m-%d').date()
                except:
                    check_out = check_in + timedelta(days=1)
            else:
                check_out = check_in + timedelta(days=1)

            # Extract fields with camelCase support (use 'is not None' to handle falsy values like 0 and empty strings)
            user_id = booking_data.get('userId') if booking_data.get('userId') is not None else booking_data.get('user_id')
            hotel_id = booking_data.get('hotelId') if booking_data.get('hotelId') is not None else booking_data.get('hotel_id')

            # For hotel_name, check if it exists and is not empty
            hotel_name = booking_data.get('hotelName')
            if not hotel_name:  # If None or empty string
                hotel_name = booking_data.get('hotel_name')
            if not hotel_name:  # If still None or empty string
                hotel_name = 'N/A'

            rooms = booking_data.get('rooms', 1)
            adults = booking_data.get('adults', 1)
            children = booking_data.get('children', 0)

            # Use 'is not None' to handle 0 values correctly (0 is falsy but valid)
            total_price = booking_data.get('totalPrice')
            if total_price is None:
                total_price = booking_data.get('total_price')
            if total_price is None:
                total_price = 0

            logger.info(f"📊 Extracted: user_id={user_id}, hotel_id={hotel_id}, hotel_name={hotel_name}, total_price={total_price}")

            booking_id = None
            booking_status = 'PENDING'

            # Insert booking only if database is reachable
            if db_reachable and conn:
                try:
                    booking_id = await conn.fetchval('''
                        INSERT INTO bookings (
                            user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                            rooms, adults, children, total_price, status, payment_status,
                            created_at, updated_at
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
                        RETURNING id
                    ''',
                    int(user_id),
                    hotel_id,
                    hotel_name,
                    check_in,
                    check_out,
                    rooms,
                    adults,
                    children,
                    float(total_price),
                    'CONFIRMED',
                    'CONFIRMED'
                    )
                    booking_status = 'CONFIRMED'
                    logger.info(f"✅ Booking created from Kafka: ID={booking_id}, User={user_id}")
                except Exception as insert_err:
                    logger.error(f"❌ Failed to insert booking: {insert_err}")
                    db_reachable = False

            # Calculate days
            days = (check_out - check_in).days

            # Publish BOOKING_CREATED notification event
            if self.notification_producer:
                try:
                    event = {
                        'eventType': 'BOOKING_CREATED',
                        'data': {
                            'bookingId': str(booking_id) if booking_id else 'N/A',
                            'userId': str(user_id),
                            'hotelId': hotel_id,
                            'hotelName': hotel_name,
                            'checkInDate': str(check_in),
                            'checkOutDate': str(check_out),
                            'rooms': rooms,
                            'adults': adults,
                            'children': children,
                            'totalPrice': float(total_price),
                            'days': days,
                            'status': booking_status,
                            'dbReachable': db_reachable,
                            'timestamp': datetime.utcnow().isoformat()
                        }
                    }
                    self.notification_producer.send('booking-events', value=event)
                    self.notification_producer.flush()
                    logger.info(f"📨 Published BOOKING_CREATED notification for user {user_id}")
                except Exception as notif_err:
                    logger.error(f"⚠️ Failed to publish notification: {notif_err}")

            return booking_id
        except Exception as e:
            logger.error(f"❌ Error processing booking request: {e}")
            raise
        finally:
            if conn:
                try:
                    await conn.close()
                except:
                    pass
    
    def consume_messages_sync(self):
        """Consume messages from Kafka (synchronous - runs in thread)"""
        self.running = True
        logger.info("🚀 Starting booking request consumer...")

        try:
            for message in self.consumer:
                if not self.running:
                    break

                try:
                    booking_data = message.value
                    logger.info(f"📨 Received booking request: {booking_data}")

                    # Process the booking using asyncio
                    loop = asyncio.new_event_loop()
                    asyncio.set_event_loop(loop)
                    try:
                        booking_id = loop.run_until_complete(self.process_booking_request(booking_data))
                        logger.info(f"✅ Successfully processed booking: {booking_id}")
                    finally:
                        loop.close()

                except Exception as e:
                    logger.error(f"❌ Error processing message: {e}")
                    continue
        except KeyboardInterrupt:
            logger.info("⏹️  Consumer interrupted")
        finally:
            self.stop()

    async def consume_messages(self):
        """Consume messages from Kafka (async wrapper)"""
        # Run the synchronous consumer in a thread
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, self.consume_messages_sync)
    
    async def stop(self):
        """Stop the consumer"""
        self.running = False
        if self.consumer:
            await self.consumer.close()
        if self.db_pool:
            await asyncio.get_event_loop().run_until_complete(self.db_pool.close())
        logger.info("🛑 Consumer stopped")

# Global consumer instance
booking_consumer = BookingRequestConsumer()

async def start_booking_consumer():
    """Start the booking consumer in background"""
    try:
        await booking_consumer.init_db_pool()
        booking_consumer.init_kafka_consumer()
        
        # Run consumer in a separate thread
        loop = asyncio.get_event_loop()
        loop.create_task(booking_consumer.consume_messages())
        logger.info("✅ Booking consumer started in background")
    except Exception as e:
        logger.error(f"❌ Failed to start booking consumer: {e}")

def stop_booking_consumer():
    """Stop the booking consumer"""
    booking_consumer.stop()

