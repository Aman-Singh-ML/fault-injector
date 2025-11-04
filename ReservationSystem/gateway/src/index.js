// Initialize tracing first
import './tracing.js';

import express from "express";
import proxy from "express-http-proxy";
import dotenv from "dotenv";
import cors from "cors";
import pkg from 'pg';
const { Pool } = pkg;
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';
import CircuitBreaker from 'opossum';
import { metricsMiddleware, register } from './metrics.js';
import notificationRoutes from './routes/notificationRoutes.js';

dotenv.config();
const app = express();

// Add metrics middleware early in the pipeline
app.use(metricsMiddleware);

// ============================================
// RATE LIMITING CONFIGURATION
// ============================================

// General API rate limiter - 100 requests per 15 minutes per IP
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// Strict rate limiter for auth endpoints - 5 requests per 15 minutes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: {
    error: 'Too many authentication attempts, please try again later.',
    retryAfter: '15 minutes'
  },
  skipSuccessfulRequests: true, // Don't count successful requests
});

// Payment rate limiter - 10 requests per 15 minutes
const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: {
    error: 'Too many payment requests, please try again later.',
    retryAfter: '15 minutes'
  },
});

// Admin rate limiter - 50 requests per 15 minutes
const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  message: {
    error: 'Too many admin requests, please try again later.',
    retryAfter: '15 minutes'
  },
});

// ============================================
// CIRCUIT BREAKER CONFIGURATION
// ============================================

const circuitBreakerOptions = {
  timeout: 90000, // If function takes longer than 90 seconds, trigger a failure (supports up to 60s broker lag + buffer)
  errorThresholdPercentage: 50, // When 50% of requests fail, open the circuit
  resetTimeout: 30000, // After 30 seconds, try again
  rollingCountTimeout: 10000, // Rolling window for error calculation
  rollingCountBuckets: 10, // Number of buckets in the rolling window
  name: 'serviceBreaker',
};

// Create circuit breakers for each service
const serviceBreakers = {
  auth: new CircuitBreaker(async (url, options) => {
    const response = await fetch(url, options);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response;
  }, { ...circuitBreakerOptions, name: 'authServiceBreaker' }),

  search: new CircuitBreaker(async (url, options) => {
    const response = await fetch(url, options);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response;
  }, { ...circuitBreakerOptions, name: 'searchServiceBreaker' }),

  booking: new CircuitBreaker(async (url, options) => {
    const response = await fetch(url, options);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response;
  }, { ...circuitBreakerOptions, name: 'bookingServiceBreaker' }),

  payment: new CircuitBreaker(async (url, options) => {
    const response = await fetch(url, options);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response;
  }, { ...circuitBreakerOptions, name: 'paymentServiceBreaker' }),
};

// Circuit breaker event listeners for monitoring
Object.entries(serviceBreakers).forEach(([serviceName, breaker]) => {
  breaker.on('open', () => console.log(`🔴 Circuit breaker OPEN for ${serviceName} service`));
  breaker.on('halfOpen', () => console.log(`🟡 Circuit breaker HALF-OPEN for ${serviceName} service`));
  breaker.on('close', () => console.log(`🟢 Circuit breaker CLOSED for ${serviceName} service`));
  breaker.on('fallback', () => console.log(`⚠️  Fallback triggered for ${serviceName} service`));
});

// Fallback responses for when services are down
const fallbackResponses = {
  auth: { error: 'Authentication service temporarily unavailable', status: 503 },
  search: { hotels: [], total: 0, message: 'Search service temporarily unavailable' },
  booking: { error: 'Booking service temporarily unavailable', status: 503 },
  payment: { error: 'Payment service temporarily unavailable', status: 503 },
};

// ============================================
// MIDDLEWARE SETUP
// ============================================

// NOTE: Auth endpoints are now proxied to the Java Auth Service
// This ensures consistent JWT token generation and validation across all services

const JWT_SECRET = process.env.JWT_SECRET || 'mySecretKeyForJWTTokenGenerationAndValidation123456789';

// Enable CORS for frontend
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

app.use(express.json());

// Service URLs - support both Docker and local development
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || "http://localhost:8080";
const SEARCH_SERVICE_URL = process.env.SEARCH_SERVICE_URL || "http://localhost:8081";
const BOOKING_SERVICE_URL = process.env.BOOKING_SERVICE_URL || "http://localhost:8000";
const PAYMENT_SERVICE_URL = process.env.PAYMENT_SERVICE_URL || "http://localhost:8082";
const NOTIFICATION_SERVICE_URL = process.env.NOTIFICATION_SERVICE_URL || "http://localhost:8083";

// Apply general rate limiting to all routes
app.use(generalLimiter);

// Auth endpoints - proxy to Java Auth Service for consistent JWT token generation
// This ensures all tokens are generated by the same service and can be validated consistently
app.post("/auth/register", authLimiter, proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => `/auth/register`,
  userResDecorator: (proxyRes, proxyResData, userReq, userRes) => {
    // Pass through the response as-is from the auth service
    return proxyResData;
  }
}));

app.post("/auth/login", authLimiter, proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => `/auth/login`,
  userResDecorator: (proxyRes, proxyResData, userReq, userRes) => {
    // Pass through the response as-is from the auth service
    return proxyResData;
  }
}));

// Profile endpoint - proxy to Java Auth Service
app.get("/auth/profile", proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => `/auth/profile`,
  userResDecorator: (proxyRes, proxyResData, userReq, userRes) => {
    // Pass through the response as-is from the auth service
    return proxyResData;
  }
}));

// Update profile endpoint - proxy to Java Auth Service
app.put("/auth/profile", proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => `/auth/profile`,
  userResDecorator: (proxyRes, proxyResData, userReq, userRes) => {
    // Pass through the response as-is from the auth service
    return proxyResData;
  }
}));

// Proxy routes (fallback to Java service if it becomes available)
// JWT verification middleware for protected routes
const verifyToken = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = {
      id: decoded.userId,
      email: decoded.email,
      role: decoded.role
    };
    next();
  } catch (error) {
    console.error('❌ Token verification error:', error.message);
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Admin routes must come BEFORE general routes to avoid conflicts
// Admin analytics aggregation endpoint (must be before other /auth routes)
app.get("/auth/admin/analytics", adminLimiter, verifyToken, async (req, res) => {
  try {
    // Fetch data from all services in parallel with circuit breaker protection
    const [usersCount, hotelsCount, bookingsCount, bookingsStats] = await Promise.all([
      serviceBreakers.auth.fire(`${AUTH_SERVICE_URL}/admin/users/count`, {
        headers: { 'Authorization': req.headers.authorization }
      })
        .then(r => r.json())
        .catch(() => ({ total: 0, customers: 0, admins: 0 })),

      serviceBreakers.search.fire(`${SEARCH_SERVICE_URL}/admin/hotels/count`, {
        headers: { 'Authorization': req.headers.authorization }
      })
        .then(r => r.json())
        .catch(() => ({ total: 0 })),

      serviceBreakers.booking.fire(`${BOOKING_SERVICE_URL}/admin/bookings/count`, {
        headers: { 'Authorization': req.headers.authorization }
      })
        .then(r => r.json())
        .catch(() => ({ total: 0, byStatus: {} })),

      serviceBreakers.booking.fire(`${BOOKING_SERVICE_URL}/admin/bookings/stats`, {
        headers: { 'Authorization': req.headers.authorization }
      })
        .then(r => r.json())
        .catch(() => ({ totalRevenue: 0 }))
    ]);

    // Aggregate the data
    const analytics = {
      totalUsers: usersCount.total || 0,
      totalHotels: hotelsCount.total || 0,
      totalBookings: bookingsCount.total || 0,
      totalRevenue: bookingsStats.totalRevenue || 0,
      recentBookings: bookingsCount.total || 0,
      activeUsers: usersCount.customers || 0,
      recentUsers: usersCount.customers || 0,
      bookingsByStatus: {
        PENDING: bookingsCount.byStatus?.pending || 0,
        CONFIRMED: bookingsCount.byStatus?.confirmed || 0,
        COMPLETED: bookingsCount.byStatus?.completed || 0,
        CANCELLED: bookingsCount.byStatus?.cancelled || 0,
      },
      usersByRole: {
        ADMIN: usersCount.admins || 0,
        USER: usersCount.customers || 0,
        CUSTOMER: usersCount.customers || 0,
      }
    };

    res.json(analytics);
  } catch (error) {
    console.error('Error fetching analytics:', error);
    res.status(500).json({
      error: 'Failed to fetch analytics',
      message: error.message
    });
  }
});

// Admin users routes
app.use("/auth/admin/users", adminLimiter, verifyToken, proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/admin/users${req.url}`;
  }
}));

// Admin hotels routes (must be before /search route)
app.use("/search/admin/hotels", adminLimiter, verifyToken, proxy(SEARCH_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/admin/hotels${req.url}`;
  }
}));

// Admin bookings routes (must be before /booking route)
app.use("/booking/admin/bookings", adminLimiter, verifyToken, proxy(BOOKING_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/admin/bookings${req.url}`;
  },
  proxyReqOptDecorator: (proxyReqOpts, srcReq) => {
    if (srcReq.user) {
      proxyReqOpts.headers['X-User-Id'] = srcReq.user.id.toString();
      proxyReqOpts.headers['X-User-Role'] = srcReq.user.role;
    }
    return proxyReqOpts;
  }
}));

// General service routes
app.use("/auth", proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/auth${req.url}`;
  },
  proxyErrorHandler: (err, res, next) => {
    // If auth service is down, the direct endpoints above will handle it
    next();
  }
}));

// Booking creation endpoint - routes to Search Service which publishes to Kafka
app.post("/bookings/create", verifyToken, proxy(SEARCH_SERVICE_URL, {
  proxyReqPathResolver: (req) => `/search/book`,
  proxyReqOptDecorator: (proxyReqOpts, srcReq) => {
    // Forward user info as headers
    proxyReqOpts.headers['X-User-Id'] = srcReq.user.id.toString();
    proxyReqOpts.headers['X-User-Role'] = srcReq.user.role;
    return proxyReqOpts;
  }
}));

app.use("/search", proxy(SEARCH_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    // Gateway receives /search/hotels, we need to pass /search/hotels to the service
    return `/search${req.url}`;
  }
}));

app.use("/booking", verifyToken, proxy(BOOKING_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    // FastAPI requires trailing slash for routes
    let path = req.url;
    // Add trailing slash for collection endpoints
    if (path === '/bookings' || path.startsWith('/bookings?')) {
      if (!path.includes('?')) {
        path = '/bookings/';
      } else {
        path = path.replace('/bookings?', '/bookings/?');
      }
    }
    return path;
  },
  proxyReqOptDecorator: (proxyReqOpts, srcReq) => {
    // Forward user info as headers
    proxyReqOpts.headers['X-User-Id'] = srcReq.user.id.toString();
    proxyReqOpts.headers['X-User-Role'] = srcReq.user.role;
    return proxyReqOpts;
  },
  userResDecorator: (proxyRes, proxyResData, userReq, userRes) => {
    // Handle redirects by following them
    if (proxyRes.statusCode === 307 || proxyRes.statusCode === 308) {
      // Return empty array for now - the path should be fixed to avoid redirects
      return proxyResData;
    }
    return proxyResData;
  }
}));

app.use("/payment", paymentLimiter, proxy(PAYMENT_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/payment${req.url}`;
  }
}));

// Use custom notification routes instead of direct proxy
app.use("/notifications", notificationRoutes);

// Additional admin routes for backward compatibility
app.use("/admin/users", adminLimiter, verifyToken, proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    let suffix = req.url === '/' ? '' : req.url;
    return `/admin/users${suffix}`;
  }
}));

app.use("/admin/bookings", adminLimiter, verifyToken, proxy(BOOKING_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    let suffix = req.url === '/' ? '' : req.url;
    return `/admin/bookings${suffix}`;
  },
  proxyReqOptDecorator: (proxyReqOpts, srcReq) => {
    if (srcReq.user) {
      proxyReqOpts.headers['X-User-Id'] = srcReq.user.id.toString();
      proxyReqOpts.headers['X-User-Role'] = srcReq.user.role;
    }
    return proxyReqOpts;
  }
}));

app.use("/admin/hotels", adminLimiter, verifyToken, proxy(SEARCH_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    // req.url is the part after /admin/hotels, e.g., "/" or "/123" or ""
    // We want to remove the leading "/" if it's just "/"
    let suffix = req.url === '/' ? '' : req.url;
    let path = `/admin/hotels${suffix}`;
    return path;
  }
}));

app.use("/admin/payments", adminLimiter, verifyToken, proxy(PAYMENT_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    let suffix = req.url === '/' ? '' : req.url;
    return `/admin/payments${suffix}`;
  }
}));

app.use("/admin/notifications", adminLimiter, verifyToken, proxy(NOTIFICATION_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    let suffix = req.url === '/' ? '' : req.url;
    return `/admin/notifications${suffix}`;
  }
}));

app.get("/", (req, res) => {
  res.json({
    message: "Hotel Reservation API Gateway",
    status: "running",
    services: {
      auth: AUTH_SERVICE_URL,
      search: SEARCH_SERVICE_URL,
      booking: BOOKING_SERVICE_URL,
      payment: PAYMENT_SERVICE_URL,
      notification: NOTIFICATION_SERVICE_URL
    }
  });
});

// Health check with circuit breaker status
app.get("/health", (req, res) => {
  const circuitBreakerStatus = {};
  Object.entries(serviceBreakers).forEach(([serviceName, breaker]) => {
    circuitBreakerStatus[serviceName] = {
      state: breaker.opened ? 'OPEN' : breaker.halfOpen ? 'HALF_OPEN' : 'CLOSED',
      stats: breaker.stats
    };
  });

  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    circuitBreakers: circuitBreakerStatus,
    rateLimiting: {
      general: "100 req/15min",
      auth: "5 req/15min",
      payment: "10 req/15min",
      admin: "50 req/15min"
    }
  });
});

// Metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (ex) {
    res.status(500).end(ex);
  }
});

const PORT = process.env.PORT || 9000;
app.listen(PORT, () => {
  console.log(`🚀 API Gateway running on port ${PORT}`);
  console.log(`📡 Services:`);
  console.log(`   - Auth: ${AUTH_SERVICE_URL}`);
  console.log(`   - Search: ${SEARCH_SERVICE_URL}`);
  console.log(`   - Booking: ${BOOKING_SERVICE_URL}`);
  console.log(`   - Payment: ${PAYMENT_SERVICE_URL}`);
  console.log(`   - Notification: ${NOTIFICATION_SERVICE_URL}`);
});