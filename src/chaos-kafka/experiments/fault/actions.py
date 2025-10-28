import json
import time
import random
import asyncio
from datetime import datetime, timedelta
from kafka import KafkaProducer
from kafka.errors import KafkaError
import logging

logger = logging.getLogger(__name__)

def generate_continuous_bookings(bootstrap_servers, topic="booking-requests", 
                                duration_seconds=60, rate_per_second=2,
                                user_id=None, hotel_name_prefix="Test Hotel",
                                booking_count=None, price_range=None):
    """
    Generate continuous booking requests to simulate real traffic
    
    Args:
        bootstrap_servers: Kafka bootstrap servers
        topic: Kafka topic name
        duration_seconds: How long to generate bookings (ignored if booking_count is set)
        rate_per_second: Rate of booking generation
        user_id: Specific user ID to use, or None for random users
        hotel_name_prefix: Prefix for hotel names (will append numbers)
        booking_count: Exact number of bookings to generate (overrides duration)
        price_range: Tuple of (min_price, max_price) or None for default
    """
    producer = KafkaProducer(
        bootstrap_servers=bootstrap_servers.split(','),
        value_serializer=lambda v: json.dumps(v).encode('utf-8'),
        key_serializer=lambda k: k.encode('utf-8') if k else None,
        retries=3,
        acks='all'
    )
    
    # Default price range
    if price_range is None:
        price_range = (100.0, 300.0)
    
    # Generate hotel list with custom prefix
    hotels = []
    for i in range(1, 11):  # Generate 10 hotels
        hotels.append({
            "id": f"hotel_{i:03d}",
            "name": f"{hotel_name_prefix} {i}",
            "price": random.uniform(price_range[0], price_range[1])
        })
    
    start_time = time.time()
    generated_count = 0
    
    # Determine if we're using booking count or duration
    use_booking_count = booking_count is not None
    target_bookings = booking_count if use_booking_count else float('inf')
    
    if use_booking_count:
        logger.info(f"🚀 Generating {booking_count} bookings at {rate_per_second} bookings/sec")
    else:
        logger.info(f"🚀 Starting continuous booking generation for {duration_seconds}s at {rate_per_second} bookings/sec")
    
    if user_id:
        logger.info(f"👤 Using specific user ID: {user_id}")
    else:
        logger.info(f"👥 Using random user IDs (1-100)")
    
    try:
        while (generated_count < target_bookings and 
               (use_booking_count or time.time() - start_time < duration_seconds)):
            
            # Generate booking data
            hotel = random.choice(hotels)
            current_user_id = user_id if user_id else random.randint(1, 100)
            
            check_in = datetime.now() + timedelta(days=random.randint(1, 30))
            check_out = check_in + timedelta(days=random.randint(1, 7))
            
            rooms = random.randint(1, 3)
            adults = random.randint(1, 4)
            children = random.randint(0, 2)
            
            nights = (check_out - check_in).days
            total_price = nights * rooms * hotel["price"]
            
            booking_request = {
                "userId": str(current_user_id),
                "hotelId": hotel["id"],
                "hotelName": hotel["name"],
                "checkInDate": check_in.strftime("%Y-%m-%d"),
                "checkOutDate": check_out.strftime("%Y-%m-%d"),
                "rooms": rooms,
                "adults": adults,
                "children": children,
                "totalPrice": round(total_price, 2),
                "timestamp": datetime.now().isoformat(),
                "test_metadata": {
                    "generated_by": "chaos_experiment",
                    "user_specified": user_id is not None,
                    "hotel_prefix": hotel_name_prefix
                }
            }
            
            # Send to Kafka
            future = producer.send(
                topic,
                key=str(current_user_id),
                value=booking_request
            )
            
            generated_count += 1
            logger.info(f"📨 Generated booking #{generated_count}: User {current_user_id} -> {hotel['name']} (${total_price:.2f})")
            
            # Rate limiting (skip if we're done with count-based generation)
            if not use_booking_count or generated_count < target_bookings:
                time.sleep(1.0 / rate_per_second)
            
    except Exception as e:
        logger.error(f"❌ Error generating bookings: {e}")
        raise
    finally:
        producer.flush()
        producer.close()
    
    elapsed_time = time.time() - start_time
    actual_rate = generated_count / elapsed_time if elapsed_time > 0 else 0
    
    logger.info(f"✅ Generated {generated_count} booking requests in {elapsed_time:.1f} seconds (actual rate: {actual_rate:.2f}/sec)")
    
    return {
        "bookings_generated": generated_count,
        "duration": elapsed_time,
        "target_rate": rate_per_second,
        "actual_rate": actual_rate,
        "user_id": user_id,
        "hotel_prefix": hotel_name_prefix
    }

def stress_booking_system(bootstrap_servers, topic="booking-requests", 
                         burst_count=50, concurrent_producers=3,
                         user_id_range=None, hotel_name_prefix="Stress Hotel",
                         price_range=None):
    """
    Create burst load with multiple concurrent producers
    
    Args:
        bootstrap_servers: Kafka bootstrap servers
        topic: Kafka topic name
        burst_count: Number of bookings per producer
        concurrent_producers: Number of concurrent producers
        user_id_range: Tuple of (min_user_id, max_user_id) or None for default
        hotel_name_prefix: Prefix for hotel names
        price_range: Tuple of (min_price, max_price) or None for default
    """
    import threading
    
    # Default ranges
    if user_id_range is None:
        user_id_range = (1, 1000)
    if price_range is None:
        price_range = (150.0, 250.0)
    
    results = []
    threads = []
    
    def producer_worker(worker_id):
        try:
            producer = KafkaProducer(
                bootstrap_servers=bootstrap_servers.split(','),
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                key_serializer=lambda k: k.encode('utf-8'),
                batch_size=16384,
                linger_ms=10
            )
            
            worker_bookings = 0
            
            for i in range(burst_count):
                # Generate user ID within specified range
                user_id = random.randint(user_id_range[0], user_id_range[1])
                
                # Generate price within range
                price_per_night = random.uniform(price_range[0], price_range[1])
                nights = random.randint(1, 5)
                rooms = random.randint(1, 2)
                total_price = nights * rooms * price_per_night
                
                booking = {
                    "userId": str(user_id),
                    "hotelId": f"stress_hotel_{worker_id}_{i}",
                    "hotelName": f"{hotel_name_prefix} {worker_id}-{i}",
                    "checkInDate": "2024-02-01",
                    "checkOutDate": "2024-02-03",
                    "rooms": rooms,
                    "adults": random.randint(1, 4),
                    "children": random.randint(0, 2),
                    "totalPrice": round(total_price, 2),
                    "timestamp": datetime.now().isoformat(),
                    "test_metadata": {
                        "stress_test": True,
                        "worker_id": worker_id,
                        "booking_sequence": i,
                        "hotel_prefix": hotel_name_prefix,
                        "user_range": user_id_range
                    }
                }
                
                producer.send(topic, key=str(user_id), value=booking)
                worker_bookings += 1
                
            producer.flush()
            producer.close()
            
            result_msg = f"Worker {worker_id} completed {worker_bookings} bookings (users {user_id_range[0]}-{user_id_range[1]})"
            results.append(result_msg)
            logger.info(f"✅ {result_msg}")
            
        except Exception as e:
            error_msg = f"Worker {worker_id} failed: {e}"
            logger.error(f"❌ {error_msg}")
            results.append(error_msg)
    
    logger.info(f"🔥 Starting stress test: {concurrent_producers} producers × {burst_count} bookings each")
    logger.info(f"👥 User ID range: {user_id_range[0]}-{user_id_range[1]}")
    logger.info(f"🏨 Hotel prefix: '{hotel_name_prefix}'")
    logger.info(f"💰 Price range: ${price_range[0]:.2f}-${price_range[1]:.2f}")
    
    # Start concurrent producers
    start_time = time.time()
    for i in range(concurrent_producers):
        thread = threading.Thread(target=producer_worker, args=(i,))
        threads.append(thread)
        thread.start()
    
    # Wait for all to complete
    for thread in threads:
        thread.join()
    
    elapsed_time = time.time() - start_time
    total_messages = concurrent_producers * burst_count
    rate = total_messages / elapsed_time if elapsed_time > 0 else 0
    
    logger.info(f"🔥 Stress test completed: {total_messages} messages from {concurrent_producers} producers in {elapsed_time:.1f}s (rate: {rate:.2f}/sec)")
    
    return {
        "total_messages": total_messages,
        "concurrent_producers": concurrent_producers,
        "elapsed_time": elapsed_time,
        "rate_per_second": rate,
        "user_id_range": user_id_range,
        "hotel_prefix": hotel_name_prefix,
        "price_range": price_range,
        "results": results
    }

def generate_user_specific_bookings(bootstrap_servers, topic="booking-requests",
                                   user_id=1, booking_count=10, 
                                   hotel_name_prefix="User Test Hotel",
                                   rate_per_second=1, price_range=None):
    """
    Generate specific number of bookings for a specific user
    
    Args:
        bootstrap_servers: Kafka bootstrap servers
        topic: Kafka topic name
        user_id: Specific user ID to generate bookings for
        booking_count: Exact number of bookings to generate
        hotel_name_prefix: Prefix for hotel names
        rate_per_second: Rate of generation
        price_range: Tuple of (min_price, max_price)
    """
    return generate_continuous_bookings(
        bootstrap_servers=bootstrap_servers,
        topic=topic,
        duration_seconds=None,  # Will be ignored
        rate_per_second=rate_per_second,
        user_id=user_id,
        hotel_name_prefix=hotel_name_prefix,
        booking_count=booking_count,
        price_range=price_range
    )