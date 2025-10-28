"""OpenTelemetry tracing setup for Booking service"""

import os
import logging
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.semconv.resource import ResourceAttributes
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

logger = logging.getLogger(__name__)

def init_tracing(service_name: str = "booking-service"):
    """Initialize OpenTelemetry tracing"""

    # Create resource
    resource = Resource.create({
        ResourceAttributes.SERVICE_NAME: service_name,
        ResourceAttributes.SERVICE_VERSION: "1.0.0",
        ResourceAttributes.DEPLOYMENT_ENVIRONMENT: os.getenv("ENVIRONMENT", "development"),
    })

    # Create tracer provider
    trace.set_tracer_provider(TracerProvider(resource=resource))
    tracer_provider = trace.get_tracer_provider()

    # Only enable Jaeger if explicitly configured
    enable_jaeger = os.getenv("ENABLE_JAEGER", "false").lower() == "true"

    if enable_jaeger:
        try:
            # Create Jaeger exporter
            jaeger_endpoint = os.getenv("JAEGER_ENDPOINT", "http://jaeger-collector:14268/api/traces")
            jaeger_exporter = JaegerExporter(
                collector_endpoint=jaeger_endpoint,
            )

            # Create span processor
            span_processor = BatchSpanProcessor(jaeger_exporter)
            tracer_provider.add_span_processor(span_processor)
            logger.info(f"🔍 OpenTelemetry tracing initialized with Jaeger for {service_name}")
        except Exception as e:
            logger.warning(f"⚠️  Could not initialize Jaeger tracing: {e}. Continuing without tracing.")
    else:
        logger.info(f"🔍 OpenTelemetry tracing initialized (Jaeger disabled) for {service_name}")

    # Auto-instrument libraries (not FastAPI - that needs app instance)
    try:
        SQLAlchemyInstrumentor().instrument()
        RedisInstrumentor().instrument()
        HTTPXClientInstrumentor().instrument()
    except Exception as e:
        logger.warning(f"⚠️  Could not instrument libraries: {e}")

    return tracer_provider

def get_tracer(name: str = "booking-service"):
    """Get a tracer instance"""
    return trace.get_tracer(name)

def shutdown_tracing():
    """Shutdown tracing"""
    tracer_provider = trace.get_tracer_provider()
    if hasattr(tracer_provider, 'shutdown'):
        tracer_provider.shutdown()
        logger.info("🔍 OpenTelemetry tracing shutdown")
