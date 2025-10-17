// Prometheus metrics for Gateway service
import promClient from 'prom-client';

// Create a Registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({
  register,
  prefix: 'gateway_',
});

// Custom metrics
export const httpRequestDuration = new promClient.Histogram({
  name: 'gateway_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code', 'service'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register],
});

export const httpRequestTotal = new promClient.Counter({
  name: 'gateway_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code', 'service'],
  registers: [register],
});

export const activeConnections = new promClient.Gauge({
  name: 'gateway_active_connections',
  help: 'Number of active connections',
  registers: [register],
});

export const serviceHealthStatus = new promClient.Gauge({
  name: 'gateway_service_health_status',
  help: 'Health status of backend services (1 = healthy, 0 = unhealthy)',
  labelNames: ['service'],
  registers: [register],
});

export const circuitBreakerStatus = new promClient.Gauge({
  name: 'gateway_circuit_breaker_status',
  help: 'Circuit breaker status (0 = closed, 1 = open, 2 = half-open)',
  labelNames: ['service'],
  registers: [register],
});

export const jwtTokensIssued = new promClient.Counter({
  name: 'gateway_jwt_tokens_issued_total',
  help: 'Total number of JWT tokens issued',
  registers: [register],
});

export const jwtTokensValidated = new promClient.Counter({
  name: 'gateway_jwt_tokens_validated_total',
  help: 'Total number of JWT tokens validated',
  labelNames: ['status'],
  registers: [register],
});

// Business metrics
export const userRegistrations = new promClient.Counter({
  name: 'gateway_user_registrations_total',
  help: 'Total number of user registrations',
  registers: [register],
});

export const userLogins = new promClient.Counter({
  name: 'gateway_user_logins_total',
  help: 'Total number of user logins',
  labelNames: ['status'],
  registers: [register],
});

export const hotelSearches = new promClient.Counter({
  name: 'gateway_hotel_searches_total',
  help: 'Total number of hotel searches',
  registers: [register],
});

export const bookingAttempts = new promClient.Counter({
  name: 'gateway_booking_attempts_total',
  help: 'Total number of booking attempts',
  labelNames: ['status'],
  registers: [register],
});

export const paymentAttempts = new promClient.Counter({
  name: 'gateway_payment_attempts_total',
  help: 'Total number of payment attempts',
  labelNames: ['status'],
  registers: [register],
});

// Middleware to track HTTP metrics
export const metricsMiddleware = (req, res, next) => {
  const start = Date.now();
  
  // Track active connections
  activeConnections.inc();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    const service = getServiceFromPath(req.path);
    
    // Record metrics
    httpRequestDuration
      .labels(req.method, route, res.statusCode, service)
      .observe(duration);
    
    httpRequestTotal
      .labels(req.method, route, res.statusCode, service)
      .inc();
    
    // Track business metrics
    trackBusinessMetrics(req, res);
    
    // Decrease active connections
    activeConnections.dec();
  });
  
  next();
};

// Helper function to determine service from path
function getServiceFromPath(path) {
  if (path.startsWith('/auth')) return 'auth-service';
  if (path.startsWith('/search')) return 'search-service';
  if (path.startsWith('/booking')) return 'booking-service';
  if (path.startsWith('/payment')) return 'payment-service';
  if (path.startsWith('/notification')) return 'notification-service';
  return 'gateway';
}

// Helper function to track business metrics
function trackBusinessMetrics(req, res) {
  const path = req.path;
  const method = req.method;
  const statusCode = res.statusCode;
  
  // Track user registrations
  if (method === 'POST' && path === '/auth/register' && statusCode === 201) {
    userRegistrations.inc();
  }
  
  // Track user logins
  if (method === 'POST' && path === '/auth/login') {
    const status = statusCode === 200 ? 'success' : 'failure';
    userLogins.labels(status).inc();
  }
  
  // Track hotel searches
  if (method === 'GET' && path.startsWith('/search/hotels')) {
    hotelSearches.inc();
  }
  
  // Track booking attempts
  if (method === 'POST' && path === '/booking/bookings') {
    const status = statusCode === 201 ? 'success' : 'failure';
    bookingAttempts.labels(status).inc();
  }
  
  // Track payment attempts
  if (method === 'POST' && path === '/payment/initiate') {
    const status = statusCode === 201 ? 'success' : 'failure';
    paymentAttempts.labels(status).inc();
  }
}

// Export the register for the metrics endpoint
export { register };

export default {
  httpRequestDuration,
  httpRequestTotal,
  activeConnections,
  serviceHealthStatus,
  circuitBreakerStatus,
  jwtTokensIssued,
  jwtTokensValidated,
  userRegistrations,
  userLogins,
  hotelSearches,
  bookingAttempts,
  paymentAttempts,
  metricsMiddleware,
  register,
};
