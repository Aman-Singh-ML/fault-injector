from fastapi import FastAPI, HTTPException, Header, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from typing import Optional
import uvicorn
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time
import asyncio
import redis
import os

from app.db.postgres import init_db
from app.api.routes import booking, admin
from app.tracing import init_tracing
from app.consumers import start_booking_consumer, stop_booking_consumer
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Initialize tracing
init_tracing("booking-service")

# Prometheus metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

app = FastAPI(
    title="Booking Service",
    description="Hotel Booking Management Service",
    version="1.0.0"
)

# Global Redis client
redis_client = None

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

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    body = await request.body()
    print(f"❌ Validation Error on {request.url}")
    print(f"❌ Errors: {exc.errors()}")
    print(f"❌ Request body: {body.decode()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()},
    )

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database and start Kafka consumer
@app.on_event("startup")
async def startup_event():
    global redis_client

    await init_db()

    # Initialize Redis cache for booking service (port 6382)
    try:
        redis_host = os.getenv('REDIS_HOST', 'localhost')
        redis_port = int(os.getenv('REDIS_PORT', '6382'))
        redis_client = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)
        redis_client.ping()
        print(f"✅ Connected to Redis at {redis_host}:{redis_port}")
    except Exception as e:
        print(f"⚠️  Warning: Could not connect to Redis: {e}")
        redis_client = None

    # Start Kafka consumer in background
    try:
        await start_booking_consumer()
    except Exception as e:
        print(f"⚠️  Warning: Could not start Kafka consumer: {e}")
        # Don't fail startup if Kafka is not available

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    stop_booking_consumer()




# Health check
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "booking-service"}

# Prometheus metrics endpoint
@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

# Include routers
app.include_router(booking.router, prefix="/bookings", tags=["bookings"])
app.include_router(admin.router, prefix="/admin", tags=["admin"])

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)

