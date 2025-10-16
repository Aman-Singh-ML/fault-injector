# Hotel Reservation System - Architecture Documentation

## Overview

This is a microservices-based hotel reservation system built with multiple technologies and programming languages, demonstrating a polyglot architecture approach.

## Architecture Diagram

```
┌─────────────┐
│   Frontend  │ (Next.js)
│  (Port 3001)│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Nginx    │ (Load Balancer)
│  (Port 80)  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ API Gateway │ (Node.js/Express)
│ (Port 3000) │
└──────┬──────┘
       │
       ├──────────────────────────────────────────┐
       │                                          │
       ▼                                          ▼
┌──────────────┐                          ┌──────────────┐
│ Auth Service │ (Java/Spring Boot)       │Search Service│ (Go)
│  (Port 8081) │                          │ (Port 8082)  │
└──────┬───────┘                          └──────┬───────┘
       │                                          │
       ▼                                          ▼
┌──────────────┐                          ┌──────────────┐
│  PostgreSQL  │                          │   MongoDB    │
│  (Port 5432) │                          │ (Port 27017) │
└──────────────┘                          └──────┬───────┘
                                                 │
       ┌─────────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│    Redis     │ (Cache)
│  (Port 6379) │
└──────────────┘

       ┌──────────────┐
       │Booking Service│ (Python/FastAPI)
       │ (Port 8083)  │
       └──────┬───────┘
              │
              ├──────────────┐
              ▼              ▼
       ┌──────────┐   ┌──────────┐
       │PostgreSQL│   │  Kafka   │
       └──────────┘   │(Port 9092)│
                      └──────────┘

       ┌──────────────┐
       │Payment Service│ (Go)
       │ (Port 8084)  │
       └──────┬───────┘
              │
              ▼
       ┌──────────────┐
       │  RabbitMQ    │
       │ (Port 5672)  │
       └──────┬───────┘
              │
              ▼
       ┌──────────────────┐
       │Notification Service│ (Python/FastAPI)
       │   (Port 8086)    │
       └──────────────────┘
```

## Services

### 1. API Gateway (Node.js/Express)
- **Port**: 3000
- **Purpose**: Single entry point for all client requests
- **Features**:
  - Request routing
  - Authentication middleware
  - Rate limiting
  - Request/response logging
  - Service proxy

### 2. Auth Service (Java/Spring Boot)
- **Port**: 8081
- **Database**: PostgreSQL
- **Purpose**: User authentication and authorization
- **Features**:
  - User registration
  - Login with JWT tokens
  - Token verification
  - Password encryption (BCrypt)
  - Role-based access control

### 3. Search Service (Go)
- **Port**: 8082
- **Database**: MongoDB (hotel data), Redis (cache)
- **Purpose**: Hotel search and availability
- **Features**:
  - Hotel search by location
  - Filter by price, rating, amenities
  - Room availability check
  - Redis caching for performance

### 4. Booking Service (Python/FastAPI)
- **Port**: 8083
- **Database**: PostgreSQL
- **Message Broker**: Kafka
- **Purpose**: Booking management
- **Features**:
  - Create bookings
  - Update bookings
  - Cancel bookings
  - Booking history
  - Event publishing to Kafka

### 5. Payment Service (Go)
- **Port**: 8084
- **Database**: PostgreSQL
- **Message Broker**: RabbitMQ
- **Purpose**: Payment processing
- **Features**:
  - Process payments
  - Refund handling
  - Payment status tracking
  - Integration with payment gateways
  - Event publishing to RabbitMQ

### 6. Inventory Service (Java/Spring Boot)
- **Port**: 8085
- **Database**: PostgreSQL
- **Purpose**: Room inventory management
- **Features**:
  - Room availability tracking
  - Inventory updates
  - Reservation locking

### 7. Notification Service (Python/FastAPI)
- **Port**: 8086
- **Message Broker**: RabbitMQ
- **Purpose**: Send notifications
- **Features**:
  - Email notifications
  - SMS notifications (future)
  - Booking confirmations
  - Payment confirmations
  - RabbitMQ consumer

### 8. Pricing Service (Java/Spring Boot)
- **Port**: 8087
- **Database**: PostgreSQL
- **Purpose**: Dynamic pricing
- **Features**:
  - Price calculation
  - Seasonal pricing
  - Demand-based pricing
  - Discount management

## Data Stores

### PostgreSQL
- **Purpose**: Primary relational database
- **Used by**: Auth, Booking, Payment, Inventory, Pricing services
- **Schema**: Users, Bookings, Payments, Rooms, Prices

### MongoDB
- **Purpose**: Document store for hotel data
- **Used by**: Search service
- **Collections**: Hotels, Rooms, Reviews

### Redis
- **Purpose**: Caching layer
- **Used by**: Search, Booking services
- **Data**: Search results, session data, rate limiting

## Message Brokers

### Kafka
- **Purpose**: Event streaming
- **Used by**: Booking service
- **Topics**: booking-events, payment-events
- **Use cases**: Event sourcing, audit logs

### RabbitMQ
- **Purpose**: Message queue
- **Used by**: Payment, Notification services
- **Queues**: booking_notifications, payment_notifications
- **Use cases**: Async notifications, task queuing

## Communication Patterns

### Synchronous (REST)
- Client → API Gateway → Services
- Service-to-service calls for immediate responses

### Asynchronous (Events)
- Booking created → Kafka → Analytics
- Payment processed → RabbitMQ → Notification service

## Deployment

### Docker Compose
- Local development
- All services in containers
- Shared network

### Kubernetes
- Production deployment
- Auto-scaling
- Load balancing
- Health checks
- Rolling updates

## Security

1. **Authentication**: JWT tokens
2. **Authorization**: Role-based access control
3. **Encryption**: HTTPS/TLS
4. **Secrets**: Environment variables
5. **API Gateway**: Rate limiting, CORS

## Scalability

1. **Horizontal scaling**: Multiple instances of each service
2. **Load balancing**: Nginx, Kubernetes ingress
3. **Caching**: Redis for frequently accessed data
4. **Database**: Read replicas, connection pooling
5. **Message queues**: Async processing

## Monitoring & Observability

1. **Health checks**: `/health` endpoints
2. **Metrics**: Spring Actuator, custom metrics
3. **Logging**: Centralized logging
4. **Tracing**: Distributed tracing (future)

## Technology Stack

| Service | Language | Framework | Database | Port |
|---------|----------|-----------|----------|------|
| Gateway | Node.js | Express | - | 3000 |
| Auth | Java 17 | Spring Boot 3.2 | PostgreSQL | 8081 |
| Search | Go 1.21 | Gin | MongoDB, Redis | 8082 |
| Booking | Python 3.11 | FastAPI | PostgreSQL | 8083 |
| Payment | Go 1.21 | Gin | PostgreSQL | 8084 |
| Inventory | Java 17 | Spring Boot 3.2 | PostgreSQL | 8085 |
| Notification | Python 3.11 | FastAPI | - | 8086 |
| Pricing | Java 17 | Spring Boot 3.2 | PostgreSQL | 8087 |
| Frontend | JavaScript | Next.js 14 | - | 3001 |

## Future Enhancements

1. Service mesh (Istio)
2. API versioning
3. GraphQL gateway
4. Real-time updates (WebSockets)
5. Mobile apps
6. Analytics service
7. Recommendation engine
8. Multi-language support
9. Payment gateway integrations
10. Advanced search (Elasticsearch)

