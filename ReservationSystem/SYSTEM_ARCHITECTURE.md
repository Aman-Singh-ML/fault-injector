# 🏗️ Hotel Reservation System - Complete Architecture

## 📊 System Overview Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND LAYER                              │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐    │
│  │              Next.js 14 Frontend (Port 3000)              │    │
│  │                                                           │    │
│  │  Public Pages:    User Pages:       Admin Pages:        │    │
│  │  • Landing        • Dashboard       • Admin Dashboard    │    │
│  │  • Login          • Search          • User Management    │    │
│  │  • Register       • Reservations    • Hotel Management   │    │
│  │  • About          • Notifications   • Booking Mgmt       │    │
│  │                   • Profile                              │    │
│  └───────────────────────────────────────────────────────────┘    │
│                              ↓ HTTP/REST                           │
└─────────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY LAYER                           │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐    │
│  │           Node.js API Gateway (Port 9000)                 │    │
│  │                                                           │    │
│  │  • Request Routing                                       │    │
│  │  • Authentication Middleware                             │    │
│  │  • CORS Configuration                                    │    │
│  │  • Load Balancing                                        │    │
│  │  • Rate Limiting                                         │    │
│  └───────────────────────────────────────────────────────────┘    │
│                              ↓                                      │
└─────────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      MICROSERVICES LAYER                            │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │ Auth Service │  │Search Service│  │Booking Svc   │            │
│  │ Java/Spring  │  │   Go/Gin     │  │Python/FastAPI│            │
│  │  Port 8080   │  │  Port 8081   │  │  Port 8000   │            │
│  │              │  │              │  │              │            │
│  │ • Login      │  │ • Search     │  │ • Create     │            │
│  │ • Register   │  │ • Filters    │  │ • View       │            │
│  │ • JWT Auth   │  │ • Hotels     │  │ • Cancel     │            │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│         │                 │                  │                     │
│         ↓                 ↓                  ↓                     │
│    PostgreSQL         MongoDB           PostgreSQL                │
│                                              │                     │
│                                              ↓                     │
│                                           Kafka                    │
│                                                                     │
│  ┌──────────────┐  ┌──────────────────────────────────┐          │
│  │Payment Svc   │  │   Notification Service           │          │
│  │   Go/Gin     │  │      Python/FastAPI              │          │
│  │  Port 8082   │  │       Port 8083                  │          │
│  │              │  │                                  │          │
│  │ • Process    │  │ • Email Notifications            │          │
│  │ • Refund     │  │ • SMS Notifications              │          │
│  │ • Status     │  │ • Push Notifications             │          │
│  └──────┬───────┘  └──────┬───────────────────────────┘          │
│         │                 │                                        │
│         ↓                 ↓                                        │
│    PostgreSQL         RabbitMQ                                    │
│         │                 ↑                                        │
│         └─────────────────┘                                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      INFRASTRUCTURE LAYER                           │
│                         (Docker Containers)                         │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │ PostgreSQL   │  │   MongoDB    │  │    Redis     │            │
│  │  Port 5432   │  │  Port 27017  │  │  Port 6379   │            │
│  │              │  │              │  │              │            │
│  │ • Auth DB    │  │ • Hotels DB  │  │ • Caching    │            │
│  │ • Booking DB │  │ • Search     │  │ • Sessions   │            │
│  │ • Payment DB │  │              │  │              │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │    Kafka     │  │  Zookeeper   │  │  RabbitMQ    │            │
│  │ Port 9092/93 │  │  Port 2181   │  │Port 5672/15672│           │
│  │              │  │              │  │              │            │
│  │ • Events     │  │ • Kafka Mgmt │  │ • Messages   │            │
│  │ • Streaming  │  │              │  │ • Queues     │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagrams

### User Registration Flow
```
User (Browser)
    │
    ├─→ POST /register (Frontend)
    │
    ├─→ POST /api/auth/register (API Gateway)
    │
    ├─→ POST /register (Auth Service)
    │
    ├─→ INSERT INTO users (PostgreSQL)
    │
    ├─→ 201 Created (Response)
    │
    └─→ Redirect to /login
```

### Hotel Search Flow
```
User (Browser)
    │
    ├─→ GET /search?city=NYC (Frontend)
    │
    ├─→ GET /api/hotels/search?city=NYC (API Gateway)
    │
    ├─→ GET /search?city=NYC (Search Service)
    │
    ├─→ db.hotels.find({city: "NYC"}) (MongoDB)
    │
    ├─→ 200 OK + Hotel List (Response)
    │
    └─→ Display Hotel Cards
```

### Booking Creation Flow
```
User (Browser)
    │
    ├─→ POST /bookings (Frontend)
    │
    ├─→ POST /api/bookings (API Gateway)
    │
    ├─→ POST /bookings (Booking Service)
    │
    ├─→ INSERT INTO bookings (PostgreSQL)
    │
    ├─→ Publish booking-event (Kafka)
    │       │
    │       ├─→ Payment Service (Consume)
    │       │       │
    │       │       ├─→ Process Payment
    │       │       │
    │       │       └─→ Publish payment-event (RabbitMQ)
    │       │
    │       └─→ Notification Service (Consume)
    │               │
    │               └─→ Send Email/SMS
    │
    ├─→ 201 Created (Response)
    │
    └─→ Redirect to /reservations
```

---

## 🗂️ Database Schema

### PostgreSQL (Auth Service)
```sql
users
├── id (UUID, PK)
├── email (VARCHAR, UNIQUE)
├── password (VARCHAR, HASHED)
├── first_name (VARCHAR)
├── last_name (VARCHAR)
├── phone_number (VARCHAR)
├── role (ENUM: ADMIN, CUSTOMER)
├── enabled (BOOLEAN)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### PostgreSQL (Booking Service)
```sql
bookings
├── id (UUID, PK)
├── user_id (UUID, FK)
├── hotel_id (VARCHAR)
├── check_in_date (DATE)
├── check_out_date (DATE)
├── number_of_guests (INTEGER)
├── total_price (DECIMAL)
├── status (ENUM: PENDING, CONFIRMED, CANCELLED, COMPLETED)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### PostgreSQL (Payment Service)
```sql
payments
├── id (UUID, PK)
├── booking_id (UUID, FK)
├── amount (DECIMAL)
├── payment_method (VARCHAR)
├── status (ENUM: PENDING, COMPLETED, FAILED, REFUNDED)
├── transaction_id (VARCHAR)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### MongoDB (Search Service)
```javascript
hotels {
  _id: ObjectId,
  name: String,
  description: String,
  address: String,
  city: String,
  country: String,
  price_per_night: Number,
  rating: Number,
  available_rooms: Number,
  amenities: [String],
  images: [String],
  created_at: Date,
  updated_at: Date
}
```

---

## 🔐 Authentication Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       ├─→ 1. Enter credentials
       │
       ↓
┌─────────────────┐
│  Login Page     │
└──────┬──────────┘
       │
       ├─→ 2. POST /api/auth/login
       │
       ↓
┌─────────────────┐
│  API Gateway    │
└──────┬──────────┘
       │
       ├─→ 3. Forward to Auth Service
       │
       ↓
┌─────────────────┐
│  Auth Service   │
└──────┬──────────┘
       │
       ├─→ 4. Verify credentials (PostgreSQL)
       │
       ├─→ 5. Generate JWT token
       │
       ↓
┌─────────────────┐
│  Response       │
│  {              │
│    token: "...",│
│    user: {...}  │
│  }              │
└──────┬──────────┘
       │
       ├─→ 6. Store in localStorage
       │
       ├─→ 7. Update Zustand store
       │
       ↓
┌─────────────────┐
│  Redirect to    │
│  Dashboard      │
└─────────────────┘
```

---

## 📡 Message Broker Flows

### Kafka (Event Streaming)
```
Booking Service
    │
    ├─→ Publish: booking-created
    │       │
    │       ├─→ Topic: booking-events
    │       │
    │       └─→ Consumers:
    │               ├─→ Payment Service
    │               └─→ Analytics Service
    │
    └─→ Publish: booking-cancelled
            │
            └─→ Topic: booking-events
```

### RabbitMQ (Message Queue)
```
Payment Service
    │
    ├─→ Publish: payment-completed
    │       │
    │       ├─→ Queue: payment_notifications
    │       │
    │       └─→ Consumer: Notification Service
    │               │
    │               └─→ Send Email/SMS
    │
    └─→ Publish: payment-failed
            │
            └─→ Queue: payment_notifications
```

---

## 🎯 Port Mapping

| Service | Port(s) | Protocol | Access |
|---------|---------|----------|--------|
| **Frontend** | 3000 | HTTP | Public |
| **API Gateway** | 9000 | HTTP | Public |
| **Auth Service** | 8080 | HTTP | Internal |
| **Search Service** | 8081 | HTTP | Internal |
| **Booking Service** | 8000 | HTTP | Internal |
| **Payment Service** | 8082 | HTTP | Internal |
| **Notification Service** | 8083 | HTTP | Internal |
| **PostgreSQL** | 5432 | TCP | Internal |
| **MongoDB** | 27017 | TCP | Internal |
| **Redis** | 6379 | TCP | Internal |
| **Kafka** | 9092, 9093 | TCP | Internal |
| **Zookeeper** | 2181 | TCP | Internal |
| **RabbitMQ** | 5672, 15672 | TCP/HTTP | Internal |

---

## 🔒 Security Layers

```
┌─────────────────────────────────────────┐
│  1. Frontend Validation                 │
│     • Form validation                   │
│     • Input sanitization                │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  2. API Gateway                         │
│     • CORS configuration                │
│     • Rate limiting                     │
│     • Request validation                │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  3. Authentication                      │
│     • JWT token verification            │
│     • Role-based access control         │
│     • Session management                │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  4. Service Layer                       │
│     • Business logic validation         │
│     • Data sanitization                 │
│     • Authorization checks              │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│  5. Database Layer                      │
│     • Parameterized queries             │
│     • Encrypted passwords               │
│     • Access control                    │
└─────────────────────────────────────────┘
```

---

## 📊 Technology Stack Summary

### Frontend
- **Framework**: Next.js 14 (React 18)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State**: Zustand
- **HTTP**: Axios
- **Icons**: React Icons
- **Notifications**: React Hot Toast

### Backend Services
- **Auth**: Java 17 + Spring Boot
- **Search**: Go 1.21 + Gin
- **Booking**: Python 3.11 + FastAPI
- **Payment**: Go 1.21 + Gin
- **Notification**: Python 3.11 + FastAPI
- **Gateway**: Node.js + Express

### Infrastructure
- **Databases**: PostgreSQL 16, MongoDB 6
- **Cache**: Redis 7
- **Message Brokers**: Kafka 7.5, RabbitMQ 3.12
- **Coordination**: Zookeeper 7.5
- **Container**: Docker

---

## 🚀 Deployment Architecture

```
┌─────────────────────────────────────────┐
│         Production Environment          │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Load Balancer (Nginx/HAProxy)   │ │
│  └───────────────┬───────────────────┘ │
│                  │                      │
│     ┌────────────┼────────────┐        │
│     ↓            ↓            ↓        │
│  ┌──────┐   ┌──────┐   ┌──────┐      │
│  │ Next │   │ Next │   │ Next │      │
│  │  #1  │   │  #2  │   │  #3  │      │
│  └──────┘   └──────┘   └──────┘      │
│                  │                      │
│                  ↓                      │
│  ┌───────────────────────────────────┐ │
│  │       API Gateway Cluster         │ │
│  └───────────────┬───────────────────┘ │
│                  │                      │
│     ┌────────────┼────────────┐        │
│     ↓            ↓            ↓        │
│  ┌──────┐   ┌──────┐   ┌──────┐      │
│  │ Svc  │   │ Svc  │   │ Svc  │      │
│  │  #1  │   │  #2  │   │  #3  │      │
│  └──────┘   └──────┘   └──────┘      │
│                  │                      │
│                  ↓                      │
│  ┌───────────────────────────────────┐ │
│  │    Infrastructure (Managed)       │ │
│  │  • RDS (PostgreSQL)               │ │
│  │  • DocumentDB (MongoDB)           │ │
│  │  • ElastiCache (Redis)            │ │
│  │  • MSK (Kafka)                    │ │
│  │  • AmazonMQ (RabbitMQ)            │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

**This architecture provides:**
- ✅ Scalability
- ✅ High Availability
- ✅ Fault Tolerance
- ✅ Security
- ✅ Performance
- ✅ Maintainability

