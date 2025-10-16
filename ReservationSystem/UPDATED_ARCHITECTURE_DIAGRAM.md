# 🏗️ Updated System Architecture - Mermaid Diagrams

**Last Updated**: 2025-10-14  
**Status**: ✅ All Features Working

---

## 📊 **DIAGRAM 1: Complete System Architecture**

```mermaid
graph TB
    subgraph "Client Layer"
        Browser["🌐 Web Browser<br/>Next.js 14 Frontend<br/>Port: 3000"]
    end

    subgraph "Load Balancer"
        NGINX["⚖️ NGINX<br/>Load Balancer<br/>Port: 80"]
    end

    subgraph "API Gateway Layer"
        Gateway["🚪 API Gateway<br/>Node.js/Express<br/>Port: 9000<br/>━━━━━━━━━━━━━━<br/>✅ Rate Limiting<br/>✅ Circuit Breaker<br/>✅ JWT Verification<br/>✅ Request Routing"]
    end

    subgraph "Microservices Layer"
        Auth["🔐 Auth Service<br/>Java/Spring Boot<br/>Port: 8080<br/>━━━━━━━━━━━━━━<br/>Database: PostgreSQL<br/>Port: 5432"]
        
        Search["🔍 Search Service<br/>Go/Gin<br/>Port: 8081<br/>━━━━━━━━━━━━━━<br/>Database: MongoDB<br/>Cache: Redis"]
        
        Booking["📅 Booking Service<br/>Python/FastAPI<br/>Port: 8000<br/>━━━━━━━━━━━━━━<br/>Database: PostgreSQL<br/>Port: 5433<br/>✅ Availability Cache"]
        
        Payment["💳 Payment Service<br/>Go/Gin<br/>Port: 8082<br/>━━━━━━━━━━━━━━<br/>Database: PostgreSQL<br/>Port: 5434<br/>✅ OTP Generation<br/>✅ FlexibleString Fix"]
        
        Notification["🔔 Notification Service<br/>Python/FastAPI<br/>Port: 8083<br/>━━━━━━━━━━━━━━<br/>Database: MongoDB<br/>Protocol: SSE"]
    end

    subgraph "Database Layer - ISOLATED INSTANCES"
        AuthDB["🗄️ PostgreSQL Auth<br/>Port: 5432<br/>Database: auth_db<br/>User: auth_user<br/>━━━━━━━━━━━━━━<br/>Tables: users"]
        
        BookingDB["🗄️ PostgreSQL Booking<br/>Port: 5433<br/>Database: booking_db<br/>User: booking_user<br/>━━━━━━━━━━━━━━<br/>Tables: bookings,<br/>room_availability"]
        
        PaymentDB["🗄️ PostgreSQL Payment<br/>Port: 5434<br/>Database: payment_db<br/>User: payment_user<br/>━━━━━━━━━━━━━━<br/>Tables: payments,<br/>payment_retry_log"]
        
        MongoDB["🗄️ MongoDB<br/>Port: 27017<br/>Database: hotel_db<br/>━━━━━━━━━━━━━━<br/>Collections: hotels,<br/>notifications"]
    end

    subgraph "Cache Layer"
        Redis["⚡ Redis<br/>Port: 6379<br/>━━━━━━━━━━━━━━<br/>✅ Search Cache (1h)<br/>✅ Session Cache (24h)<br/>✅ Rate Limiting (15m)<br/>✅ Availability Cache (5m)"]
    end

    subgraph "Message Brokers"
        Kafka["📨 Apache Kafka<br/>Ports: 9092, 9093<br/>━━━━━━━━━━━━━━<br/>Topics:<br/>• booking-events<br/>• payment-events"]
        
        RabbitMQ["🐰 RabbitMQ<br/>Ports: 5672, 15672<br/>━━━━━━━━━━━━━━<br/>Exchanges:<br/>• payment_events<br/>• user_events"]
        
        Zookeeper["🔧 Zookeeper<br/>Port: 2181<br/>━━━━━━━━━━━━━━<br/>Kafka Coordination"]
    end

    %% Client Connections
    Browser -->|HTTP/HTTPS| NGINX
    NGINX -->|Proxy| Gateway

    %% Gateway to Services
    Gateway -->|HTTP| Auth
    Gateway -->|HTTP| Search
    Gateway -->|HTTP| Booking
    Gateway -->|HTTP| Payment
    Gateway -->|HTTP| Notification
    Gateway -.->|Direct Query| AuthDB

    %% Service to Database
    Auth -->|PostgreSQL Wire| AuthDB
    Search -->|MongoDB Wire| MongoDB
    Booking -->|PostgreSQL Wire| BookingDB
    Payment -->|PostgreSQL Wire| PaymentDB
    Notification -->|MongoDB Wire| MongoDB

    %% Service to Cache
    Search -->|RESP| Redis
    Booking -->|RESP| Redis
    Gateway -->|RESP| Redis

    %% Service to Message Brokers
    Booking -->|Kafka Binary| Kafka
    Payment -->|Kafka Binary| Kafka
    Payment -->|AMQP 0.9.1| RabbitMQ
    Notification -->|Kafka Binary| Kafka
    Notification -->|AMQP 0.9.1| RabbitMQ

    %% Kafka Dependencies
    Kafka -->|ZK Protocol| Zookeeper

    %% Styling
    classDef frontend fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef gateway fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef service fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef database fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef cache fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef broker fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    
    class Browser frontend
    class NGINX,Gateway gateway
    class Auth,Search,Booking,Payment,Notification service
    class AuthDB,BookingDB,PaymentDB,MongoDB database
    class Redis cache
    class Kafka,RabbitMQ,Zookeeper broker
```

---

## 📊 **DIAGRAM 2: Complete Workflow - Booking & Payment**

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant F as 🌐 Frontend
    participant G as 🚪 Gateway
    participant B as 📅 Booking Service
    participant P as 💳 Payment Service
    participant N as 🔔 Notification Service
    participant BDB as 🗄️ Booking DB
    participant PDB as 🗄️ Payment DB
    participant K as 📨 Kafka
    participant R as 🐰 RabbitMQ
    participant Redis as ⚡ Redis

    %% Login Flow
    rect rgb(230, 245, 255)
        Note over U,G: 1. AUTHENTICATION
        U->>F: Enter credentials
        F->>G: POST /auth/login
        G->>G: Verify with bcrypt
        G->>G: Generate JWT token
        G-->>F: Return token + user info
        F-->>U: Login successful
    end

    %% Search Flow
    rect rgb(255, 243, 230)
        Note over U,Redis: 2. HOTEL SEARCH
        U->>F: Search hotels
        F->>G: GET /search/hotels
        G->>Redis: Check cache
        alt Cache Hit
            Redis-->>G: Return cached results
        else Cache Miss
            G->>G: Query MongoDB
            G->>Redis: Store in cache (1h TTL)
        end
        G-->>F: Return hotel list
        F-->>U: Display hotels
    end

    %% Booking Flow
    rect rgb(243, 229, 245)
        Note over U,K: 3. CREATE BOOKING
        U->>F: Select hotel & dates
        F->>G: POST /booking/bookings
        G->>B: Forward request
        B->>Redis: Check availability cache
        alt Cache Hit
            Redis-->>B: Return availability
        else Cache Miss
            B->>BDB: Query availability
            B->>Redis: Cache result (5m TTL)
        end
        B->>BDB: INSERT booking (status=PENDING)
        BDB-->>B: Booking created (ID=6)
        B->>K: Publish BOOKING_CREATED event
        B->>Redis: Invalidate availability cache
        B-->>G: Return booking details
        G-->>F: Booking created
        F-->>U: Show booking confirmation
    end

    %% Payment Initiation
    rect rgb(232, 245, 233)
        Note over U,R: 4. INITIATE PAYMENT
        F->>G: POST /payment/initiate
        G->>P: Forward request
        P->>P: Generate 6-digit OTP
        P->>PDB: INSERT payment (status=PENDING)
        PDB-->>P: Payment created (ID=24)
        P->>R: Publish payment.initiated event
        P-->>G: Return paymentId + OTP
        G-->>F: Payment initiated
        F-->>U: Display OTP input
    end

    %% OTP Verification
    rect rgb(255, 249, 196)
        Note over U,K: 5. VERIFY OTP
        U->>F: Enter OTP
        F->>G: POST /payment/verify-otp
        G->>P: Forward request (paymentId + OTP)
        P->>P: Convert FlexibleString to int
        P->>PDB: SELECT payment WHERE id=24
        PDB-->>P: Return payment + stored OTP
        P->>P: Compare OTP
        alt OTP Valid
            P->>P: Generate transaction ID
            P->>PDB: UPDATE payment (status=COMPLETED)
            P->>K: Publish payment.success event
            P->>R: Publish payment.completed event
            P-->>G: Payment completed
            G-->>F: Success response
            F-->>U: Payment successful!
        else OTP Invalid
            P->>K: Publish payment.failed event
            P->>R: Publish payment.failed event
            P-->>G: Invalid OTP error
            G-->>F: Error response
            F-->>U: Invalid OTP, try again
        end
    end

    %% Notification Flow
    rect rgb(252, 228, 236)
        Note over K,U: 6. NOTIFICATIONS
        K->>N: Consume booking/payment events
        R->>N: Consume payment events
        N->>N: Process events
        N->>N: Store in MongoDB
        N->>F: Send via SSE stream
        F-->>U: Show real-time notification
    end

    %% Booking Confirmation
    rect rgb(230, 245, 255)
        Note over B,BDB: 7. UPDATE BOOKING STATUS
        K->>B: Consume payment.success event
        B->>BDB: UPDATE booking (status=CONFIRMED)
        B->>K: Publish BOOKING_CONFIRMED event
    end
```

---

## 📊 **DIAGRAM 3: Database Isolation Architecture**

```mermaid
graph LR
    subgraph "Microservices"
        Auth["🔐 Auth Service<br/>Port: 8080"]
        Booking["📅 Booking Service<br/>Port: 8000"]
        Payment["💳 Payment Service<br/>Port: 8082"]
    end

    subgraph "Isolated PostgreSQL Instances"
        AuthDB["🗄️ PostgreSQL 1<br/>Port: 5432<br/>━━━━━━━━━━━━━━<br/>Database: auth_db<br/>User: auth_user<br/>Password: auth_pass<br/>━━━━━━━━━━━━━━<br/>Tables:<br/>• users (3 rows)"]
        
        BookingDB["🗄️ PostgreSQL 2<br/>Port: 5433<br/>━━━━━━━━━━━━━━<br/>Database: booking_db<br/>User: booking_user<br/>Password: booking_pass<br/>━━━━━━━━━━━━━━<br/>Tables:<br/>• bookings<br/>• room_availability"]
        
        PaymentDB["🗄️ PostgreSQL 3<br/>Port: 5434<br/>━━━━━━━━━━━━━━<br/>Database: payment_db<br/>User: payment_user<br/>Password: payment_pass<br/>━━━━━━━━━━━━━━<br/>Tables:<br/>• payments (24 rows)<br/>• payment_retry_log"]
    end

    Auth -->|"postgresql://auth_user:auth_pass@localhost:5432/auth_db"| AuthDB
    Booking -->|"postgresql://booking_user:booking_pass@localhost:5433/booking_db"| BookingDB
    Payment -->|"postgresql://payment_user:payment_pass@localhost:5434/payment_db"| PaymentDB

    classDef service fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef database fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px
    
    class Auth,Booking,Payment service
    class AuthDB,BookingDB,PaymentDB database
```

---

## 📊 **DIAGRAM 4: Redis Multi-Purpose Caching**

```mermaid
graph TB
    subgraph "Services"
        Gateway["🚪 Gateway"]
        Search["🔍 Search"]
        Booking["📅 Booking"]
    end

    subgraph "Redis Cache - Port 6379"
        Redis["⚡ Redis Server"]
        
        subgraph "Cache Types"
            SearchCache["🔍 Search Results Cache<br/>TTL: 1 hour<br/>Key: search:*"]
            SessionCache["🔐 Session Cache<br/>TTL: 24 hours<br/>Key: session:*"]
            RateLimitCache["⏱️ Rate Limit Store<br/>TTL: 15 minutes<br/>Key: ratelimit:*"]
            AvailCache["📅 Availability Cache<br/>TTL: 5 minutes<br/>Key: availability:*<br/>✅ Auto-invalidation"]
        end
    end

    Gateway -->|Rate Limiting| RateLimitCache
    Gateway -->|Session Storage| SessionCache
    Search -->|Cache Results| SearchCache
    Booking -->|Cache Availability| AvailCache
    
    SearchCache -.-> Redis
    SessionCache -.-> Redis
    RateLimitCache -.-> Redis
    AvailCache -.-> Redis

    classDef service fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef cache fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    class Gateway,Search,Booking service
    class Redis,SearchCache,SessionCache,RateLimitCache,AvailCache cache
```

---

## 📊 **DIAGRAM 5: Message Broker Architecture**

```mermaid
graph TB
    subgraph "Producers"
        Booking["📅 Booking Service"]
        Payment["💳 Payment Service"]
    end

    subgraph "Apache Kafka - Ports 9092/9093"
        Kafka["📨 Kafka Broker"]
        
        subgraph "Topics"
            BookingTopic["📋 booking-events<br/>━━━━━━━━━━━━━━<br/>Events:<br/>• BOOKING_CREATED<br/>• BOOKING_CONFIRMED<br/>• BOOKING_CANCELLED"]
            
            PaymentTopic["💰 payment-events<br/>━━━━━━━━━━━━━━<br/>Events:<br/>• PAYMENT_INITIATED<br/>• PAYMENT_SUCCESS<br/>• PAYMENT_FAILED"]
        end
    end

    subgraph "RabbitMQ - Ports 5672/15672"
        RabbitMQ["🐰 RabbitMQ Broker"]
        
        subgraph "Exchanges"
            PaymentExchange["💳 payment_events<br/>Type: topic<br/>━━━━━━━━━━━━━━<br/>Routing Keys:<br/>• payment.initiated<br/>• payment.completed<br/>• payment.failed"]
            
            UserExchange["👤 user_events<br/>Type: topic<br/>━━━━━━━━━━━━━━<br/>Routing Keys:<br/>• user.registered<br/>• user.updated"]
        end
    end

    subgraph "Consumers"
        Notification["🔔 Notification Service"]
        BookingConsumer["📅 Booking Service<br/>(Consumer)"]
    end

    subgraph "Coordination"
        Zookeeper["🔧 Zookeeper<br/>Port: 2181"]
    end

    Booking -->|Publish| BookingTopic
    Payment -->|Publish| PaymentTopic
    Payment -->|Publish| PaymentExchange
    
    BookingTopic -->|Subscribe| Notification
    PaymentTopic -->|Subscribe| Notification
    PaymentTopic -->|Subscribe| BookingConsumer
    PaymentExchange -->|Subscribe| Notification
    
    Kafka -.->|Coordination| Zookeeper

    classDef service fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef broker fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    
    class Booking,Payment,Notification,BookingConsumer service
    class Kafka,RabbitMQ,Zookeeper,BookingTopic,PaymentTopic,PaymentExchange,UserExchange broker
```

---

## 📊 **DIAGRAM 6: Gateway Features - Rate Limiting & Circuit Breaker**

```mermaid
graph TB
    subgraph "Client Requests"
        Client["👤 Client"]
    end

    subgraph "API Gateway - Port 9000"
        Gateway["🚪 Express Gateway"]
        
        subgraph "Rate Limiting"
            GeneralLimit["⏱️ General API<br/>100 req / 15 min"]
            AuthLimit["🔐 Auth Endpoints<br/>5 req / 15 min"]
            PaymentLimit["💳 Payment Endpoints<br/>10 req / 15 min"]
            AdminLimit["👨‍💼 Admin Endpoints<br/>50 req / 15 min"]
        end
        
        subgraph "Circuit Breakers"
            AuthCB["🔴 Auth Circuit<br/>Timeout: 10s<br/>Threshold: 50%<br/>Reset: 30s"]
            SearchCB["🟢 Search Circuit<br/>Timeout: 10s<br/>Threshold: 50%<br/>Reset: 30s"]
            BookingCB["🔴 Booking Circuit<br/>Timeout: 10s<br/>Threshold: 50%<br/>Reset: 30s"]
            PaymentCB["🟢 Payment Circuit<br/>Timeout: 10s<br/>Threshold: 50%<br/>Reset: 30s"]
        end
    end

    subgraph "Backend Services"
        Auth["🔐 Auth Service"]
        Search["🔍 Search Service"]
        Booking["📅 Booking Service"]
        Payment["💳 Payment Service"]
    end

    Client -->|Request| Gateway
    Gateway --> GeneralLimit
    Gateway --> AuthLimit
    Gateway --> PaymentLimit
    Gateway --> AdminLimit
    
    AuthCB -->|Proxy| Auth
    SearchCB -->|Proxy| Search
    BookingCB -->|Proxy| Booking
    PaymentCB -->|Proxy| Payment

    classDef client fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef gateway fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef service fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef limit fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef cb fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    
    class Client client
    class Gateway gateway
    class Auth,Search,Booking,Payment service
    class GeneralLimit,AuthLimit,PaymentLimit,AdminLimit limit
    class AuthCB,SearchCB,BookingCB,PaymentCB cb
```

---

## 📝 **Architecture Summary**

### **Technology Stack**:
- **Frontend**: Next.js 14, React, TypeScript, Zustand, Axios
- **API Gateway**: Node.js, Express, express-rate-limit, opossum
- **Microservices**: 
  - Auth: Java/Spring Boot
  - Search: Go/Gin
  - Booking: Python/FastAPI
  - Payment: Go/Gin
  - Notification: Python/FastAPI
- **Databases**: 
  - PostgreSQL 16 (3 isolated instances)
  - MongoDB 6
- **Cache**: Redis 7
- **Message Brokers**: Kafka, RabbitMQ
- **Load Balancer**: NGINX

### **Key Features Implemented**:
✅ Database Isolation (3 separate PostgreSQL instances)  
✅ Redis Multi-Purpose Caching (4 strategies)  
✅ Rate Limiting (4 different limits)  
✅ Circuit Breaker Pattern  
✅ OTP-Based Payment Verification  
✅ Real-time Notifications (SSE)  
✅ Event-Driven Architecture (Kafka + RabbitMQ)  
✅ JWT Authentication  
✅ Admin Panel with Analytics  

### **Ports Reference**:
- Frontend: 3000
- Gateway: 9000
- Auth: 8080
- Search: 8081
- Booking: 8000
- Payment: 8082
- Notification: 8083
- PostgreSQL Auth: 5432
- PostgreSQL Booking: 5433
- PostgreSQL Payment: 5434
- MongoDB: 27017
- Redis: 6379
- Kafka: 9092, 9093
- RabbitMQ: 5672, 15672
- Zookeeper: 2181
- NGINX: 80

---

**Last Updated**: 2025-10-14  
**Status**: ✅ All diagrams reflect current working system

