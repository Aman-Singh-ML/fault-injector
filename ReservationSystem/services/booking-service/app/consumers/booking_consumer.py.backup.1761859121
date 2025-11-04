import json
import asyncio
import asyncpg
import os
import threading
from kafka import KafkaConsumer
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BookingRequestConsumer:
    def __init__(self):
        self.consumer = None
        self.db_pool = None
        self.running = False
        
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
                session_timeout_ms=10000,
                request_timeout_ms=15000,
                connections_max_idle_ms=30000,
                reconnect_backoff_ms=100,
                reconnect_backoff_max_ms=1000
            )
            logger.info(f"✅ Kafka consumer initialized for topic: booking-requests on kafka-booking instance: {kafka_servers}")
        except Exception as e:
            logger.error(f"❌ Failed to initialize Kafka consumer: {e}")
            raise
    
    async def process_booking_request(self, booking_data):
        """Process a booking request from Kafka"""
        conn = None
        try:
            # Create a new connection for this request
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

            # Parse dates - convert string to date object
            check_in_str = booking_data.get('checkInDate')
            check_out_str = booking_data.get('checkOutDate')

            # Parse dates from string format (YYYY-MM-DD)
            try:
                check_in = datetime.strptime(check_in_str, '%Y-%m-%d').date() if isinstance(check_in_str, str) else check_in_str
                check_out = datetime.strptime(check_out_str, '%Y-%m-%d').date() if isinstance(check_out_str, str) else check_out_str
            except (ValueError, TypeError) as e:
                logger.error(f"❌ Error parsing dates: {e}")
                check_in = check_in_str
                check_out = check_out_str

            # Insert booking
            booking_id = await conn.fetchval('''
                INSERT INTO bookings (
                    user_id, hotel_id, hotel_name, check_in_date, check_out_date,
                    rooms, adults, children, total_price, status, payment_status,
                    created_at, updated_at
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
                RETURNING id
            ''',
            int(booking_data['userId']),
            booking_data['hotelId'],
            booking_data['hotelName'],
            check_in,
            check_out,
            booking_data['rooms'],
            booking_data['adults'],
            booking_data['children'],
            float(booking_data['totalPrice']),
            'CONFIRMED',
            'CONFIRMED'
            )

            logger.info(f"✅ Booking created from Kafka: ID={booking_id}, User={booking_data['userId']}")
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

