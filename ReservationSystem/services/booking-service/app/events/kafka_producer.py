from kafka import KafkaProducer
import json
import os

KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")

producer = None

def get_kafka_producer():
    global producer
    if producer is None:
        producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
    return producer

async def publish_booking_event(event_type: str, data: dict):
    """Publish booking events to Kafka"""
    try:
        kafka_producer = get_kafka_producer()
        message = {
            "event_type": event_type,
            "data": data
        }
        kafka_producer.send("booking-events", value=message)
        kafka_producer.flush()
        print(f"Published event: {event_type}")
    except Exception as e:
        print(f"Error publishing event: {e}")

