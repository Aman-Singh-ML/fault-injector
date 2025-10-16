# Hotel Reservation System - Setup Guide

## 📋 Complete Project Structure Created

All files and folders have been successfully created according to your specification!

## 🎯 What Has Been Created

### 1. Deployment Configuration (`deploy/`)
- ✅ `docker-compose.yml` - Complete Docker Compose setup for all services
- ✅ `nginx/nginx.conf` - Nginx reverse proxy configuration
- ✅ `nginx/Dockerfile` - Nginx container configuration
- ✅ `k8s/` - Kubernetes deployment manifests for all services:
  - postgres-statefulset.yaml
  - redis-deployment.yaml
  - mongo-deployment.yaml
  - kafka-deployment.yaml
  - rabbitmq-deployment.yaml
  - auth-deployment.yaml
  - booking-deployment.yaml
  - nginx-deployment.yaml

### 2. API Gateway (`gateway/`)
- ✅ Node.js/Express API Gateway
- ✅ Routes for booking, search, and payment
- ✅ Authentication middleware
- ✅ Service proxy utility
- ✅ Dockerfile and package.json

### 3. Auth Service (`services/auth-service/`)
- ✅ Java/Spring Boot authentication service
- ✅ JWT token generation and verification
- ✅ User registration and login
- ✅ PostgreSQL integration
- ✅ Complete MVC structure (Model, Repository, Service, Controller)
- ✅ Security configuration with BCrypt

### 4. Search Service (`services/search-service/`)
- ✅ Go-based hotel search service
- ✅ MongoDB integration for hotel data
- ✅ Redis caching layer
- ✅ Gin web framework
- ✅ Complete project structure (cmd, internal/handlers, models, repository, cache)

### 5. Booking Service (`services/booking-service/`)
- ✅ Python/FastAPI booking management
- ✅ PostgreSQL database integration
- ✅ Redis caching
- ✅ Kafka event publishing
- ✅ Complete API routes and models

### 6. Payment Service (`services/payment-service/`)
- ✅ Go-based payment processing
- ✅ RabbitMQ integration
- ✅ Payment gateway simulation
- ✅ Refund handling

### 7. Inventory Service (`services/inventory-service/`)
- ✅ Java/Spring Boot room inventory management
- ✅ PostgreSQL integration
- ✅ Complete Spring Boot structure

### 8. Notification Service (`services/notification-service/`)
- ✅ Python/FastAPI notification service
- ✅ RabbitMQ consumer
- ✅ Email sending functionality
- ✅ Async message processing

### 9. Pricing Service (`services/pricing-service/`)
- ✅ Java/Spring Boot dynamic pricing
- ✅ PostgreSQL integration
- ✅ Complete Spring Boot structure

### 10. Frontend (`frontend/`)
- ✅ Next.js 14 application
- ✅ Tailwind CSS styling
- ✅ Pages: Home, Search, Booking, Payment
- ✅ Responsive design
- ✅ API integration

### 11. Documentation (`docs/`)
- ✅ Architecture documentation
- ✅ OpenAPI specifications for Auth, Booking, and Payment APIs
- ✅ Development guide
- ✅ README with setup instructions

## 🚀 Quick Start Instructions

### Option 1: Docker Compose (Recommended for Quick Start)

```bash
# Navigate to deploy directory
cd deploy

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Access the application
# Frontend: http://localhost:3001
# API Gateway: http://localhost:3000
# Nginx: http://localhost
```

### Option 2: Run Services Individually

#### Prerequisites
Install the following on your system:
- Node.js 18+
- Java 17+ (with Maven)
- Go 1.21+
- Python 3.11+
- PostgreSQL 15
- MongoDB 6
- Redis 7
- Kafka
- RabbitMQ

#### Start Infrastructure Services

```bash
# PostgreSQL
docker run -d -p 5432:5432 -e POSTGRES_DB=hotel_db -e POSTGRES_USER=hotel_user -e POSTGRES_PASSWORD=hotel_pass postgres:15-alpine

# MongoDB
docker run -d -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=admin -e MONGO_INITDB_ROOT_PASSWORD=admin123 mongo:6

# Redis
docker run -d -p 6379:6379 redis:7-alpine

# RabbitMQ
docker run -d -p 5672:5672 -p 15672:15672 rabbitmq:3-management-alpine

# Kafka (requires Zookeeper)
docker run -d -p 2181:2181 confluentinc/cp-zookeeper:7.5.0 -e ZOOKEEPER_CLIENT_PORT=2181
docker run -d -p 9092:9092 confluentinc/cp-kafka:7.5.0 -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181
```

#### Start Backend Services

```bash
# Auth Service (Java)
cd services/auth-service
mvn spring-boot:run

# Search Service (Go)
cd services/search-service
go mod download
go run cmd/main.go

# Booking Service (Python)
cd services/booking-service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8083

# Payment Service (Go)
cd services/payment-service
go mod download
go run cmd/main.go

# Inventory Service (Java)
cd services/inventory-service
mvn spring-boot:run

# Notification Service (Python)
cd services/notification-service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8086

# Pricing Service (Java)
cd services/pricing-service
mvn spring-boot:run
```

#### Start Gateway and Frontend

```bash
# API Gateway
cd gateway
npm install
npm run dev

# Frontend
cd frontend
npm install
npm run dev
```

## 🔧 Configuration

### Environment Variables

Each service has a `.env.example` file. Copy it to `.env` and adjust as needed:

```bash
# Gateway
cp gateway/.env.example gateway/.env

# Booking Service
cp services/booking-service/.env.example services/booking-service/.env

# Notification Service
cp services/notification-service/.env.example services/notification-service/.env

# Frontend
cp frontend/.env.example frontend/.env
```

## 📊 Service Ports

| Service | Port | URL |
|---------|------|-----|
| Frontend | 3001 | http://localhost:3001 |
| API Gateway | 3000 | http://localhost:3000 |
| Nginx | 80 | http://localhost |
| Auth Service | 8081 | http://localhost:8081 |
| Search Service | 8082 | http://localhost:8082 |
| Booking Service | 8083 | http://localhost:8083 |
| Payment Service | 8084 | http://localhost:8084 |
| Inventory Service | 8085 | http://localhost:8085 |
| Notification Service | 8086 | http://localhost:8086 |
| Pricing Service | 8087 | http://localhost:8087 |
| PostgreSQL | 5432 | localhost:5432 |
| MongoDB | 27017 | localhost:27017 |
| Redis | 6379 | localhost:6379 |
| Kafka | 9092 | localhost:9092 |
| RabbitMQ | 5672 | localhost:5672 |
| RabbitMQ Management | 15672 | http://localhost:15672 |

## 🧪 Testing the System

### 1. Health Checks

```bash
# Check all services
curl http://localhost:8081/health  # Auth
curl http://localhost:8082/health  # Search
curl http://localhost:8083/health  # Booking
curl http://localhost:8084/health  # Payment
curl http://localhost:8085/health  # Inventory
curl http://localhost:8086/health  # Notification
curl http://localhost:8087/health  # Pricing
```

### 2. Register a User

```bash
curl -X POST http://localhost:8081/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "phoneNumber": "+1234567890"
  }'
```

### 3. Login

```bash
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 4. Search Hotels

```bash
curl "http://localhost:8082/search?location=NewYork&checkIn=2024-01-15&checkOut=2024-01-20&guests=2&rooms=1"
```

## 📚 Next Steps

1. **Customize Services**: Add your business logic to each service
2. **Database Schemas**: Define proper database schemas for each service
3. **Add Tests**: Write unit and integration tests
4. **Security**: Implement proper security measures
5. **Monitoring**: Add logging and monitoring solutions
6. **CI/CD**: Set up continuous integration and deployment
7. **API Documentation**: Enhance OpenAPI specifications

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Find process using port
lsof -i :8081

# Kill process
kill -9 <PID>
```

### Database Connection Issues
- Ensure PostgreSQL/MongoDB are running
- Check connection strings in environment variables
- Verify credentials

### Docker Issues
```bash
# Clean up Docker
docker-compose down -v
docker system prune -a

# Rebuild
docker-compose build --no-cache
docker-compose up -d
```

## 📖 Additional Resources

- [Architecture Documentation](./docs/architecture.md)
- [API Specifications](./docs/api-specs/)
- [Development Guide](./docs/readme.md)

## 🎉 Success!

Your complete Hotel Reservation System microservices architecture is now set up and ready for development!

All services are configured with:
- ✅ Proper project structure
- ✅ Dockerfiles for containerization
- ✅ Kubernetes manifests for orchestration
- ✅ Database integrations
- ✅ Message broker integrations
- ✅ API endpoints
- ✅ Documentation

Happy coding! 🚀

