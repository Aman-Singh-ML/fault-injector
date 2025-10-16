# Hotel Reservation System - Documentation

## Table of Contents

1. [Architecture Overview](./architecture.md)
2. [API Specifications](#api-specifications)
3. [Getting Started](#getting-started)
4. [Development Guide](#development-guide)
5. [Deployment](#deployment)

## API Specifications

- [Auth Service API](./api-specs/auth-openapi.yaml)
- [Booking Service API](./api-specs/booking-openapi.yaml)
- [Payment Service API](./api-specs/payment-openapi.yaml)

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Node.js 18+ (for gateway and frontend)
- Java 17+ (for Java services)
- Go 1.21+ (for Go services)
- Python 3.11+ (for Python services)

### Quick Start with Docker Compose

```bash
# Clone the repository
git clone <repository-url>
cd ReservationSystem

# Start all services
cd deploy
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### Access Points

- Frontend: http://localhost:3001
- API Gateway: http://localhost:3000
- Nginx: http://localhost
- Auth Service: http://localhost:8081
- Search Service: http://localhost:8082
- Booking Service: http://localhost:8083
- Payment Service: http://localhost:8084
- Inventory Service: http://localhost:8085
- Notification Service: http://localhost:8086
- Pricing Service: http://localhost:8087

### Database Access

- PostgreSQL: localhost:5432
  - Database: hotel_db
  - Username: hotel_user
  - Password: hotel_pass

- MongoDB: localhost:27017
  - Username: admin
  - Password: admin123

- Redis: localhost:6379

### Message Brokers

- Kafka: localhost:9092
- RabbitMQ: localhost:5672
- RabbitMQ Management: http://localhost:15672 (guest/guest)

## Development Guide

### Running Individual Services

#### Gateway (Node.js)
```bash
cd gateway
npm install
npm run dev
```

#### Auth Service (Java)
```bash
cd services/auth-service
mvn spring-boot:run
```

#### Search Service (Go)
```bash
cd services/search-service
go mod download
go run cmd/main.go
```

#### Booking Service (Python)
```bash
cd services/booking-service
pip install -r requirements.txt
uvicorn app.main:app --reload
```

#### Payment Service (Go)
```bash
cd services/payment-service
go mod download
go run cmd/main.go
```

#### Frontend (Next.js)
```bash
cd frontend
npm install
npm run dev
```

### Environment Variables

Each service can be configured using environment variables. See individual service directories for `.env.example` files.

## Deployment

### Kubernetes Deployment

```bash
# Apply all Kubernetes manifests
kubectl apply -f deploy/k8s/

# Check deployment status
kubectl get pods
kubectl get services

# View logs
kubectl logs -f <pod-name>
```

### Building Docker Images

```bash
# Build all images
docker-compose build

# Build specific service
docker build -t hotel/auth-service:latest services/auth-service
```

## Testing

### API Testing

Use the provided OpenAPI specifications with tools like:
- Postman
- Swagger UI
- Insomnia

### Example API Calls

#### Register User
```bash
curl -X POST http://localhost:8081/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'
```

#### Search Hotels
```bash
curl "http://localhost:8082/search?location=NewYork&checkIn=2024-01-15&checkOut=2024-01-20"
```

## Monitoring

### Health Checks

All services expose a `/health` endpoint:

```bash
curl http://localhost:8081/health  # Auth Service
curl http://localhost:8082/health  # Search Service
curl http://localhost:8083/health  # Booking Service
```

### Metrics

Spring Boot services expose actuator endpoints:

```bash
curl http://localhost:8081/actuator/health
curl http://localhost:8081/actuator/metrics
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure no other services are using the required ports
2. **Database connection**: Check if PostgreSQL/MongoDB are running
3. **Message broker**: Verify Kafka/RabbitMQ are accessible

### Logs

```bash
# Docker Compose logs
docker-compose logs -f <service-name>

# Kubernetes logs
kubectl logs -f <pod-name>
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License

