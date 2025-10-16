# Hotel Reservation System

A comprehensive microservices-based hotel reservation system built with multiple technologies demonstrating a polyglot architecture.

## 🏗️ Architecture

This system consists of 8 microservices built with different technologies:

- **API Gateway** (Node.js/Express) - Single entry point for all requests
- **Auth Service** (Java/Spring Boot) - User authentication & authorization
- **Search Service** (Go) - Hotel search with caching
- **Booking Service** (Python/FastAPI) - Booking management
- **Payment Service** (Go) - Payment processing
- **Inventory Service** (Java/Spring Boot) - Room inventory management
- **Notification Service** (Python/FastAPI) - Email/SMS notifications
- **Pricing Service** (Java/Spring Boot) - Dynamic pricing
- **Frontend** (Next.js) - User interface

## 🛠️ Technology Stack

| Component | Technology |
|-----------|-----------|
| **Languages** | Java 17, Go 1.21, Python 3.11, JavaScript/Node.js 18 |
| **Frameworks** | Spring Boot 3.2, Gin, FastAPI, Express, Next.js 14 |
| **Databases** | PostgreSQL 15, MongoDB 6, Redis 7 |
| **Message Brokers** | Apache Kafka, RabbitMQ |
| **Containerization** | Docker, Docker Compose |
| **Orchestration** | Kubernetes |
| **Load Balancer** | Nginx |

## 📁 Project Structure

```
ReservationSystem/
├── deploy/                    # Deployment configurations
│   ├── docker-compose.yml
│   ├── k8s/                  # Kubernetes manifests
│   └── nginx/                # Nginx configuration
├── gateway/                   # API Gateway (Node.js)
├── services/
│   ├── auth-service/         # Java/Spring Boot
│   ├── search-service/       # Go
│   ├── booking-service/      # Python/FastAPI
│   ├── payment-service/      # Go
│   ├── inventory-service/    # Java/Spring Boot
│   ├── notification-service/ # Python/FastAPI
│   └── pricing-service/      # Java/Spring Boot
├── frontend/                  # Next.js application
└── docs/                      # Documentation
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 18+
- Java 17+
- Go 1.21+
- Python 3.11+

### Running with Docker Compose

```bash
# Start all services
cd deploy
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Access the Application

- **Frontend**: http://localhost:3001
- **API Gateway**: http://localhost:3000
- **Nginx Load Balancer**: http://localhost
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

### Individual Service Ports

- Auth Service: 8081
- Search Service: 8082
- Booking Service: 8083
- Payment Service: 8084
- Inventory Service: 8085
- Notification Service: 8086
- Pricing Service: 8087

## 📚 Documentation

- [Architecture Documentation](./docs/architecture.md)
- [API Specifications](./docs/api-specs/)
- [Development Guide](./docs/readme.md)

## 🔧 Development

### Running Services Locally

#### Gateway
```bash
cd gateway
npm install
npm run dev
```

#### Auth Service
```bash
cd services/auth-service
mvn spring-boot:run
```

#### Search Service
```bash
cd services/search-service
go run cmd/main.go
```

#### Booking Service
```bash
cd services/booking-service
pip install -r requirements.txt
uvicorn app.main:app --reload
```

#### Frontend
```bash
cd frontend
npm install
npm run dev
```

## 🐳 Docker Images

Build individual service images:

```bash
# Auth Service
docker build -t hotel/auth-service:latest services/auth-service

# Search Service
docker build -t hotel/search-service:latest services/search-service

# Booking Service
docker build -t hotel/booking-service:latest services/booking-service

# Payment Service
docker build -t hotel/payment-service:latest services/payment-service

# Frontend
docker build -t hotel/frontend:latest frontend

# Gateway
docker build -t hotel/gateway:latest gateway
```

## ☸️ Kubernetes Deployment

```bash
# Apply all manifests
kubectl apply -f deploy/k8s/

# Check deployments
kubectl get deployments
kubectl get pods
kubectl get services

# View logs
kubectl logs -f <pod-name>
```

## 🔐 Environment Variables

### Database Configuration
- `POSTGRES_URL`: PostgreSQL connection string
- `MONGO_URI`: MongoDB connection string
- `REDIS_URL`: Redis connection string

### Service URLs
- `AUTH_SERVICE_URL`: Auth service endpoint
- `SEARCH_SERVICE_URL`: Search service endpoint
- `BOOKING_SERVICE_URL`: Booking service endpoint
- `PAYMENT_SERVICE_URL`: Payment service endpoint

### Message Brokers
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka broker addresses
- `RABBITMQ_URL`: RabbitMQ connection string

## 🧪 Testing

### Health Checks

```bash
# Check all services
curl http://localhost:8081/health  # Auth
curl http://localhost:8082/health  # Search
curl http://localhost:8083/health  # Booking
curl http://localhost:8084/health  # Payment
```

### API Testing

Use the OpenAPI specifications in `docs/api-specs/` with:
- Postman
- Swagger UI
- Insomnia

## 📊 Features

### User Features
- ✅ User registration and authentication
- ✅ Hotel search with filters
- ✅ Room availability checking
- ✅ Booking creation and management
- ✅ Payment processing
- ✅ Email notifications
- ✅ Booking history

### Technical Features
- ✅ Microservices architecture
- ✅ Polyglot persistence
- ✅ Event-driven communication
- ✅ Caching with Redis
- ✅ Message queues (Kafka, RabbitMQ)
- ✅ JWT authentication
- ✅ Docker containerization
- ✅ Kubernetes orchestration
- ✅ Load balancing with Nginx
- ✅ Health checks and monitoring

## 🔄 Data Flow

1. **User Registration/Login** → Auth Service → JWT Token
2. **Hotel Search** → Search Service → MongoDB/Redis
3. **Create Booking** → Booking Service → PostgreSQL → Kafka Event
4. **Process Payment** → Payment Service → PostgreSQL → RabbitMQ
5. **Send Notification** → Notification Service (consumes from RabbitMQ)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 👥 Authors

- Your Name

## 🙏 Acknowledgments

- Spring Boot for Java microservices
- FastAPI for Python services
- Gin framework for Go services
- Next.js for the frontend
- Docker and Kubernetes for containerization

## 📞 Support

For support, email support@hotel.com or open an issue in the repository.

---

**Note**: This is a demonstration project showcasing microservices architecture with multiple technologies. For production use, additional security, monitoring, and scaling considerations should be implemented.

