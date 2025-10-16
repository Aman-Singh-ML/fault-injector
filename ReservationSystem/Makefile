.PHONY: help build up down logs clean install-deps

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Docker Compose Commands
build: ## Build all Docker images
	cd deploy && docker-compose build

up: ## Start all services with Docker Compose
	cd deploy && docker-compose up -d

down: ## Stop all services
	cd deploy && docker-compose down

logs: ## View logs from all services
	cd deploy && docker-compose logs -f

ps: ## Show running containers
	cd deploy && docker-compose ps

restart: ## Restart all services
	cd deploy && docker-compose restart

clean: ## Remove all containers, volumes, and images
	cd deploy && docker-compose down -v
	docker system prune -af

# Individual Service Commands
gateway: ## Run API Gateway locally
	cd gateway && npm install && npm run dev

auth: ## Run Auth Service locally
	cd services/auth-service && mvn spring-boot:run

search: ## Run Search Service locally
	cd services/search-service && go run cmd/main.go

booking: ## Run Booking Service locally
	cd services/booking-service && uvicorn app.main:app --reload --port 8083

payment: ## Run Payment Service locally
	cd services/payment-service && go run cmd/main.go

inventory: ## Run Inventory Service locally
	cd services/inventory-service && mvn spring-boot:run

notification: ## Run Notification Service locally
	cd services/notification-service && uvicorn app.main:app --reload --port 8086

pricing: ## Run Pricing Service locally
	cd services/pricing-service && mvn spring-boot:run

frontend: ## Run Frontend locally
	cd frontend && npm install && npm run dev

# Installation Commands
install-deps: ## Install dependencies for all services
	@echo "Installing Gateway dependencies..."
	cd gateway && npm install
	@echo "Installing Frontend dependencies..."
	cd frontend && npm install
	@echo "Installing Booking Service dependencies..."
	cd services/booking-service && pip install -r requirements.txt
	@echo "Installing Notification Service dependencies..."
	cd services/notification-service && pip install -r requirements.txt
	@echo "Downloading Go modules for Search Service..."
	cd services/search-service && go mod download
	@echo "Downloading Go modules for Payment Service..."
	cd services/payment-service && go mod download
	@echo "Done!"

# Health Check Commands
health: ## Check health of all services
	@echo "Checking Auth Service..."
	@curl -s http://localhost:8081/health || echo "Auth Service not responding"
	@echo "\nChecking Search Service..."
	@curl -s http://localhost:8082/health || echo "Search Service not responding"
	@echo "\nChecking Booking Service..."
	@curl -s http://localhost:8083/health || echo "Booking Service not responding"
	@echo "\nChecking Payment Service..."
	@curl -s http://localhost:8084/health || echo "Payment Service not responding"
	@echo "\nChecking Inventory Service..."
	@curl -s http://localhost:8085/health || echo "Inventory Service not responding"
	@echo "\nChecking Notification Service..."
	@curl -s http://localhost:8086/health || echo "Notification Service not responding"
	@echo "\nChecking Pricing Service..."
	@curl -s http://localhost:8087/health || echo "Pricing Service not responding"

# Kubernetes Commands
k8s-deploy: ## Deploy to Kubernetes
	kubectl apply -f deploy/k8s/

k8s-delete: ## Delete Kubernetes deployments
	kubectl delete -f deploy/k8s/

k8s-status: ## Show Kubernetes deployment status
	kubectl get pods
	kubectl get services
	kubectl get deployments

# Database Commands
db-start: ## Start only database services
	cd deploy && docker-compose up -d postgres mongodb redis

db-stop: ## Stop database services
	cd deploy && docker-compose stop postgres mongodb redis

# Message Broker Commands
mq-start: ## Start message broker services
	cd deploy && docker-compose up -d kafka zookeeper rabbitmq

mq-stop: ## Stop message broker services
	cd deploy && docker-compose stop kafka zookeeper rabbitmq

# Development Commands
dev-infra: ## Start only infrastructure (databases, message brokers)
	cd deploy && docker-compose up -d postgres mongodb redis kafka zookeeper rabbitmq

dev-services: ## Start all backend services (requires dev-infra)
	@echo "Starting all backend services..."
	@echo "Make sure to run 'make dev-infra' first!"
	@echo "Run each service in a separate terminal:"
	@echo "  make auth"
	@echo "  make search"
	@echo "  make booking"
	@echo "  make payment"
	@echo "  make inventory"
	@echo "  make notification"
	@echo "  make pricing"
	@echo "  make gateway"
	@echo "  make frontend"

# Testing Commands
test-auth: ## Test Auth Service
	curl -X POST http://localhost:8081/auth/register \
		-H "Content-Type: application/json" \
		-d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User"}'

test-search: ## Test Search Service
	curl "http://localhost:8082/search?location=NewYork&checkIn=2024-01-15&checkOut=2024-01-20"

# Build Individual Docker Images
build-gateway: ## Build Gateway Docker image
	docker build -t hotel/gateway:latest gateway

build-auth: ## Build Auth Service Docker image
	docker build -t hotel/auth-service:latest services/auth-service

build-search: ## Build Search Service Docker image
	docker build -t hotel/search-service:latest services/search-service

build-booking: ## Build Booking Service Docker image
	docker build -t hotel/booking-service:latest services/booking-service

build-payment: ## Build Payment Service Docker image
	docker build -t hotel/payment-service:latest services/payment-service

build-inventory: ## Build Inventory Service Docker image
	docker build -t hotel/inventory-service:latest services/inventory-service

build-notification: ## Build Notification Service Docker image
	docker build -t hotel/notification-service:latest services/notification-service

build-pricing: ## Build Pricing Service Docker image
	docker build -t hotel/pricing-service:latest services/pricing-service

build-frontend: ## Build Frontend Docker image
	docker build -t hotel/frontend:latest frontend

# Quick Start
quick-start: ## Quick start with Docker Compose
	@echo "Starting Hotel Reservation System..."
	cd deploy && docker-compose up -d
	@echo "Waiting for services to start..."
	@sleep 10
	@echo "Services started!"
	@echo "Frontend: http://localhost:3001"
	@echo "API Gateway: http://localhost:3000"
	@echo "Nginx: http://localhost"
	@echo "RabbitMQ Management: http://localhost:15672 (guest/guest)"
	@make ps

