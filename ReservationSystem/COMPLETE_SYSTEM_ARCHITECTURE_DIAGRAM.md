# 🏨 Hotel Reservation System - Complete Architecture Documentation

## 📊 **System Overview**

This document provides a comprehensive overview of the Hotel Reservation System architecture, including all protocols, databases, message brokers, caching layers, and the newly implemented API Gateway enhancements.

---

## 🎯 **Architecture Highlights**

### **✨ Recent Enhancements (Task 1 Complete)**
- ✅ **Rate Limiting** - Per-IP rate limiting with different limits for different endpoint types
- ✅ **Circuit Breaker Pattern** - Automatic failure detection and recovery for all microservices
- ✅ **Enhanced Health Monitoring** - Real-time circuit breaker status and statistics
- ✅ **Fallback Responses** - Graceful degradation when services are unavailable

---

## 🏗️ **System Components**

### **1. Client Layer**
- **Technology**: Next.js 14 with React, TypeScript
- **Port**: 3000
- **State Management**: Zustand with persist middleware
- **Authentication**: JWT tokens stored in localStorage
- **Real-time**: Server-Sent Events (SSE) for notifications

### **2. Load Balancer & Reverse Proxy**
- **Technology**: NGINX
- **Port**: 80 (HTTP/HTTPS)
- **Features**:
  - Load balancing across multiple gateway instances
  - Rate limiting (5 requests/second)
  - Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
  - Upstream routing to API Gateway

### **3. API Gateway (ENHANCED ✨)**
- **Technology**: Node.js with Express
- **Port**: 9000
- **Protocol**: HTTP/REST

#### **🆕 Rate Limiting Configuration**
| Endpoint Type | Limit | Window | Notes |
|--------------|-------|--------|-------|
| General API | 100 requests | 15 minutes | Per IP address |
| Auth Endpoints | 5 requests | 15 minutes | Only failed attempts count |
| Payment Endpoints | 10 requests | 15 minutes | Per IP address |
| Admin Endpoints | 50 requests | 15 minutes | Per IP address |

#### **🆕 Circuit Breaker Configuration**
- **Library**: opossum
- **Timeout**: 10 seconds
- **Error Threshold**: 50%
- **Reset Timeout**: 30 seconds
- **States**: OPEN, CLOSED, HALF_OPEN
- **Protected Services**: Auth, Search, Booking, Payment

#### **Features**:
- JWT verification and token generation
- Request routing to microservices
- Analytics aggregation from multiple services
- Fallback responses for service failures
- Health monitoring endpoint with circuit breaker status
- Direct PostgreSQL connection for auth endpoints

---

## 🔧 **Microservices**

### **Auth Service**
- **Technology**: Java 17 with Spring Boot
- **Port**: 8080
- **Protocol**: HTTP/REST
- **Database**: PostgreSQL (hotel_db)
- **Cache**: Redis (session cache, TTL: 1 hour)
- **Message Broker**: RabbitMQ (user events)
- **Features**:
  - User registration and authentication
  - JWT token generation (24-hour expiration)
  - Role-based access control (CUSTOMER, ADMIN, HOTEL_MANAGER)
  - Admin user management endpoints
  - Session caching in Redis

### **Search Service**
- **Technology**: Go with Gin framework
- **Port**: 8081
- **Protocol**: HTTP/REST
- **Database**: MongoDB (hotel_db.hotels collection)
- **Cache**: Redis (search results, TTL: 5 minutes)
- **Features**:
  - Hotel search with filtering and sorting
  - Redis caching for search results
  - Admin hotel management endpoints
  - MongoDB aggregation pipelines

### **Booking Service**
- **Technology**: Python with FastAPI
- **Port**: 8000
- **Protocol**: HTTP/REST
- **Database**: PostgreSQL (hotel_db.bookings table)
- **Cache**: Redis (booking cache, TTL: 1 hour)
- **Message Broker**: Kafka (booking events producer)
- **Features**:
  - Booking creation and management
  - User isolation (users see only their bookings)
  - Admin booking management
  - Kafka event publishing (BOOKING_CREATED, BOOKING_CONFIRMED, BOOKING_CANCELLED)
  - Redis caching for booking data

### **Payment Service**
- **Technology**: Go with Gin framework
- **Port**: 8082
- **Protocol**: HTTP/REST
- **Database**: PostgreSQL (hotel_db.payments table)
- **Message Broker**: RabbitMQ (payment events publisher)
- **Features**:
  - OTP-based payment simulation (6-digit OTP)
  - Payment initiation and verification
  - Transaction management
  - RabbitMQ event publishing (payment.success, payment.failed)
  - Admin payment management

### **Notification Service**
- **Technology**: Python with FastAPI
- **Port**: 8083
- **Protocol**: HTTP/REST + Server-Sent Events (SSE)
- **Database**: MongoDB (hotel_db.notifications collection)
- **Message Broker**: Kafka (consumer), RabbitMQ (consumer)
- **Features**:
  - Real-time notifications via SSE
  - Kafka event consumption (booking-events, payment-events)
  - RabbitMQ event consumption (payment events)
  - Notification storage in MongoDB
  - Admin notification management

---

## 🗄️ **Databases**

### **PostgreSQL (Port 5432)**
- **Protocol**: PostgreSQL Wire Protocol
- **Database**: hotel_db (shared database - currently)
- **Connection Libraries**:
  - Auth Service: JDBC Driver with connection pooling
  - Booking Service: asyncpg (async Python driver)
  - Payment Service: database/sql (Go standard library)
  - Gateway: pg (Node.js driver with connection pool)

#### **Tables**:
1. **users** (Auth Service)
   - id, email, password (bcrypt), first_name, last_name, phone_number, role, enabled, created_at, updated_at

2. **bookings** (Booking Service)
   - id, user_id, hotel_id, hotel_name, check_in_date, check_out_date, rooms, adults, children, total_price, status, payment_status, payment_id, transaction_id, created_at, updated_at

3. **payments** (Payment Service)
   - id, booking_id, user_id, amount, currency, status, payment_method, transaction_id, otp, created_at, updated_at

### **MongoDB (Port 27017)**
- **Protocol**: MongoDB Wire Protocol with BSON
- **Database**: hotel_db
- **Connection Libraries**:
  - Search Service: mongo-driver (Go)
  - Notification Service: motor (async Python driver)

#### **Collections**:
1. **hotels** (Search Service)
   - Hotel documents with name, location, amenities, pricing, ratings

2. **notifications** (Notification Service)
   - userId, type, title, message, data, read, createdAt

---

## ⚡ **Caching Layer - Redis (Port 6379)**

### **Protocol**: RESP (Redis Serialization Protocol)

### **🆕 Multi-Purpose Caching**:

#### **1. Search Results Cache**
- **Used by**: Search Service
- **TTL**: 5 minutes (300 seconds)
- **Key Pattern**: `search:hotels:*`
- **Operations**: GET, SET, DEL
- **Purpose**: Cache hotel search results to reduce MongoDB queries

#### **2. Session Cache**
- **Used by**: Auth Service
- **TTL**: 1 hour (3600 seconds)
- **Key Pattern**: `user:session:{userId}`
- **Operations**: GET, SET
- **Purpose**: Cache user session data after login

#### **3. Booking Cache**
- **Used by**: Booking Service
- **TTL**: 1 hour (3600 seconds)
- **Key Pattern**: `booking:{bookingId}`
- **Operations**: GET, SET, DEL
- **Purpose**: Cache booking data for faster retrieval

#### **4. Rate Limiting Storage**
- **Used by**: API Gateway
- **TTL**: 15 minutes (900 seconds)
- **Key Pattern**: `ratelimit:*`
- **Operations**: INCR, EXPIRE
- **Purpose**: Track request counts for rate limiting

---

## 📨 **Message Brokers**

### **Apache Kafka (Ports 9092/9093)**
- **Protocol**: Kafka Binary Protocol
- **Port 9092**: Internal communication
- **Port 9093**: External communication
- **Coordination**: Zookeeper (Port 2181)

#### **Topics**:
1. **booking-events**
   - **Partitions**: 3
   - **Replication Factor**: 1
   - **Events**:
     - `BOOKING_CREATED` - Published by Booking Service
     - `BOOKING_CONFIRMED` - Published by Payment Service
     - `BOOKING_CANCELLED` - Published by Booking Service
   - **Consumers**: Notification Service (group: notification-service)

2. **payment-events**
   - **Events**:
     - `PAYMENT_INITIATED`
     - `PAYMENT_COMPLETED`
   - **Consumers**: Notification Service

#### **Features**:
- Event streaming and event sourcing
- Consumer groups for scalability
- Offset management for reliable delivery
- JSON serialization for event data

### **RabbitMQ (Ports 5672/15672)**
- **Protocol**: AMQP 0.9.1
- **Port 5672**: AMQP protocol
- **Port 15672**: Management UI
- **Credentials**: admin/admin

#### **Exchanges**:
1. **payment_events** (Type: Topic)
   - **Routing Keys**:
     - `payment.success` - Published by Payment Service
     - `payment.failed` - Published by Payment Service
   - **Durable**: true

2. **user_events** (Type: Topic)
   - **Routing Keys**:
     - `user.registered` - Published by Auth Service
     - `user.login` - Published by Auth Service
   - **Durable**: true

#### **Queues**:
- `booking_notifications` (durable)
- `payment_notifications` (durable)

#### **Features**:
- Durable queues for message persistence
- Topic exchanges for flexible routing
- Auto-acknowledge mode
- Dead letter exchange support

---

## 🔄 **Communication Protocols**

| Protocol | Port | Used By | Purpose |
|----------|------|---------|---------|
| HTTP/HTTPS | 80/443 | NGINX → Gateway | Load balancing and reverse proxy |
| HTTP/REST | 9000 | Gateway → Services | API communication |
| PostgreSQL Wire | 5432 | Services → PostgreSQL | Database queries |
| MongoDB Wire | 27017 | Services → MongoDB | Document queries with BSON |
| RESP | 6379 | Services → Redis | Caching operations |
| Kafka Binary | 9092/9093 | Services → Kafka | Event streaming |
| AMQP 0.9.1 | 5672 | Services → RabbitMQ | Message queuing |
| Zookeeper | 2181 | Kafka → Zookeeper | Cluster coordination |
| SSE | 8083 | Notification → Browser | Real-time push notifications |

---

## 📋 **Complete Workflow Summary**

### **1. User Login with Rate Limiting**
1. User submits credentials → NGINX → Gateway
2. Gateway checks rate limit (5 req/15min for auth)
3. If exceeded → 429 Too Many Requests
4. Gateway checks circuit breaker status
5. If OPEN → 503 Service Unavailable (fallback)
6. Gateway forwards to Auth Service (circuit breaker protected)
7. Auth validates credentials against PostgreSQL
8. Auth generates JWT token (24-hour expiration)
9. Auth caches session in Redis (TTL: 1 hour)
10. Auth publishes `user.login` event to RabbitMQ
11. Return token to user → stored in localStorage

### **2. Hotel Search with Redis Caching**
1. User searches hotels → Gateway verifies JWT
2. Gateway checks circuit breaker → forwards to Search Service
3. Search Service checks Redis cache (`search:hotels:*`)
4. If cache hit → return cached results
5. If cache miss → query MongoDB
6. Store results in Redis (TTL: 5 minutes)
7. Return results to user

### **3. Booking Creation with Kafka Events**
1. User creates booking → Gateway verifies JWT
2. Gateway extracts userId and role from JWT
3. Gateway adds X-User-Id and X-User-Role headers
4. Gateway checks circuit breaker → forwards to Booking Service
5. Booking Service inserts into PostgreSQL (status: PENDING)
6. Booking Service caches in Redis (TTL: 1 hour)
7. Booking Service publishes `BOOKING_CREATED` event to Kafka
8. Notification Service consumes event → stores in MongoDB
9. Notification Service sends SSE notification to user
10. Return booking confirmation to user

### **4. Payment with OTP & RabbitMQ**
1. User initiates payment → Gateway rate limits (10 req/15min)
2. Payment Service generates 6-digit OTP
3. Payment Service stores in PostgreSQL (status: PENDING)
4. OTP displayed to user (simulating SMS)
5. User enters OTP → Payment Service verifies
6. If valid:
   - Update payment status to COMPLETED
   - Publish `payment.success` to RabbitMQ
   - Publish `BOOKING_CONFIRMED` to Kafka
   - Notification Service sends SSE notification
   - Booking Service updates booking status to CONFIRMED
7. If invalid → Publish `payment.failed` to RabbitMQ

### **5. Real-time Notifications via SSE**
1. User opens SSE connection → `/notifications/stream/{userId}`
2. Notification Service maintains keep-alive connection
3. When events arrive from Kafka/RabbitMQ:
   - Match userId
   - Send SSE event to browser
   - Format: `data: {type, title, message}\n\n`

### **6. Admin Analytics with Circuit Breaker**
1. Admin requests analytics → Gateway verifies JWT (role: ADMIN)
2. Gateway rate limits (50 req/15min for admin)
3. Gateway makes parallel calls to all services (circuit breaker protected):
   - Auth Service → user counts
   - Search Service → hotel counts
   - Booking Service → booking counts and stats
4. Gateway aggregates results
5. If any service fails → use fallback values (e.g., {total: 0})
6. Return aggregated analytics to admin

---

## 🎯 **Key Features**

### **Resilience & Reliability**
- ✅ Circuit breaker pattern prevents cascading failures
- ✅ Rate limiting protects against abuse
- ✅ Fallback responses ensure graceful degradation
- ✅ Health monitoring for real-time status

### **Performance**
- ✅ Redis caching reduces database load
- ✅ Connection pooling for database efficiency
- ✅ Async operations in Python services
- ✅ Parallel service calls in analytics

### **Security**
- ✅ JWT-based authentication
- ✅ Role-based access control (RBAC)
- ✅ Rate limiting per endpoint type
- ✅ NGINX security headers
- ✅ User isolation (users see only their data)

### **Scalability**
- ✅ Microservices architecture
- ✅ Event-driven communication
- ✅ Kafka consumer groups
- ✅ Horizontal scaling ready
- ✅ Load balancing with NGINX

### **Observability**
- ✅ Circuit breaker event logging
- ✅ Health check endpoints
- ✅ Rate limit headers in responses
- ✅ Service-specific logging

---

## 📊 **Technology Stack Summary**

| Component | Technology | Language | Port |
|-----------|-----------|----------|------|
| Frontend | Next.js 14 | TypeScript | 3000 |
| Load Balancer | NGINX | - | 80 |
| API Gateway | Express | Node.js | 9000 |
| Auth Service | Spring Boot | Java 17 | 8080 |
| Search Service | Gin | Go | 8081 |
| Booking Service | FastAPI | Python 3.11 | 8000 |
| Payment Service | Gin | Go | 8082 |
| Notification Service | FastAPI | Python 3.11 | 8083 |
| PostgreSQL | PostgreSQL 16 | - | 5432 |
| MongoDB | MongoDB 6 | - | 27017 |
| Redis | Redis 7 | - | 6379 |
| Kafka | Apache Kafka 3 | - | 9092/9093 |
| Zookeeper | Apache Zookeeper 3 | - | 2181 |
| RabbitMQ | RabbitMQ 3.12 | - | 5672/15672 |

---

## 🚀 **Next Steps (Pending Tasks)**

### **Task 2: gRPC Setup for Inter-Service Communication**
- Set up .proto files for Booking and Payment services
- Implement gRPC servers in services
- Add gRPC clients in Gateway
- Use gRPC for performance-sensitive operations

### **Task 3: Redis Multi-Purpose Caching Enhancement**
- ✅ Session cache (DONE)
- ✅ Search results cache (DONE)
- ✅ Booking cache (DONE)
- ✅ Rate limiting storage (DONE)
- 🔄 Booking availability cache (PENDING)

### **Task 4: Database Isolation**
- Separate PostgreSQL instances for Auth, Booking, Payment
- Update docker-compose with separate containers
- Update service configurations

### **Task 5: Testing & Validation**
- Test rate limiting behavior
- Test circuit breaker fallback
- Test gRPC performance
- Validate database isolation
- Ensure original functionality intact

---

## 📝 **Notes**

- All services are containerized and orchestrated with Docker Compose
- The system uses polyglot persistence (PostgreSQL + MongoDB)
- Event-driven architecture with Kafka and RabbitMQ
- Real-time notifications using Server-Sent Events (SSE)
- JWT tokens expire after 24 hours
- Redis caches have different TTLs based on use case
- Circuit breakers automatically recover after 30 seconds
- Rate limits are per-IP address

---

**Last Updated**: 2025-10-13  
**Version**: 1.1 (with Gateway Enhancements)  
**Status**: Task 1 Complete ✅

