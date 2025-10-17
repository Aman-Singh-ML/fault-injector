"""Prometheus metrics for Booking service"""

import time
import logging
from typing import Optional
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Request, Response
from fastapi.responses import Response as FastAPIResponse

logger = logging.getLogger(__name__)

# HTTP metrics
http_requests_total = Counter(
    'booking_service_http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status_code']
)

http_request_duration_seconds = Histogram(
    'booking_service_http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

# Database metrics
db_operations_total = Counter(
    'booking_service_db_operations_total',
    'Total database operations',
    ['operation', 'table', 'status']
)

db_operation_duration_seconds = Histogram(
    'booking_service_db_operation_duration_seconds',
    'Database operation duration in seconds',
    ['operation', 'table']
)

db_connections_active = Gauge(
    'booking_service_db_connections_active',
    'Number of active database connections'
)

# Business metrics
bookings_total = Counter(
    'booking_service_bookings_total',
    'Total number of bookings',
    ['status', 'hotel_id']
)

booking_value_total = Counter(
    'booking_service_booking_value_total',
    'Total booking value in USD'
)

booking_duration_seconds = Histogram(
    'booking_service_booking_duration_seconds',
    'Booking operation duration in seconds'
)

availability_checks_total = Counter(
    'booking_service_availability_checks_total',
    'Total availability checks',
    ['hotel_id', 'result']
)

booking_cancellations_total = Counter(
    'booking_service_booking_cancellations_total',
    'Total booking cancellations',
    ['reason']
)

# Cache metrics
cache_operations_total = Counter(
    'booking_service_cache_operations_total',
    'Total cache operations',
    ['operation', 'result']
)

cache_hit_ratio = Gauge(
    'booking_service_cache_hit_ratio',
    'Cache hit ratio'
)

# Kafka metrics
kafka_messages_total = Counter(
    'booking_service_kafka_messages_total',
    'Total Kafka messages',
    ['topic', 'status']
)

kafka_message_duration_seconds = Histogram(
    'booking_service_kafka_message_duration_seconds',
    'Kafka message processing duration in seconds',
    ['topic']
)

class MetricsMiddleware:
    """FastAPI middleware for collecting metrics"""
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        start_time = time.time()
        request = Request(scope, receive)
        
        # Create a custom send function to capture response
        status_code = 500
        
        async def send_wrapper(message):
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
            await send(message)
        
        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            # Record metrics
            duration = time.time() - start_time
            method = request.method
            path = request.url.path
            
            http_requests_total.labels(
                method=method,
                endpoint=path,
                status_code=status_code
            ).inc()
            
            http_request_duration_seconds.labels(
                method=method,
                endpoint=path
            ).observe(duration)

async def metrics_endpoint():
    """Prometheus metrics endpoint"""
    return FastAPIResponse(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )

# Business metric helpers
def record_booking(status: str, hotel_id: str, value: float = 0.0):
    """Record a booking attempt"""
    bookings_total.labels(status=status, hotel_id=hotel_id).inc()
    if value > 0:
        booking_value_total.inc(value)

def record_booking_duration(duration: float):
    """Record booking operation duration"""
    booking_duration_seconds.observe(duration)

def record_availability_check(hotel_id: str, result: str):
    """Record availability check"""
    availability_checks_total.labels(hotel_id=hotel_id, result=result).inc()

def record_booking_cancellation(reason: str):
    """Record booking cancellation"""
    booking_cancellations_total.labels(reason=reason).inc()

def record_db_operation(operation: str, table: str, status: str, duration: float):
    """Record database operation"""
    db_operations_total.labels(operation=operation, table=table, status=status).inc()
    db_operation_duration_seconds.labels(operation=operation, table=table).observe(duration)

def record_cache_operation(operation: str, result: str):
    """Record cache operation"""
    cache_operations_total.labels(operation=operation, result=result).inc()

def update_cache_hit_ratio(ratio: float):
    """Update cache hit ratio"""
    cache_hit_ratio.set(ratio)

def record_kafka_message(topic: str, status: str, duration: Optional[float] = None):
    """Record Kafka message"""
    kafka_messages_total.labels(topic=topic, status=status).inc()
    if duration is not None:
        kafka_message_duration_seconds.labels(topic=topic).observe(duration)

def update_db_connections(count: int):
    """Update active database connections count"""
    db_connections_active.set(count)

logger.info("📊 Prometheus metrics initialized for booking service")
