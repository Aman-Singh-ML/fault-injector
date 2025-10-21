# Hotel Reservation System - Deployment Guide

A cloud-native, polyglot microservices-based hotel reservation system with comprehensive observability stack.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Building Docker Images](#building-docker-images)
- [Deploying to Kubernetes](#deploying-to-kubernetes)
- [Accessing Services](#accessing-services)
- [Observability Stack](#observability-stack)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

### Microservices (Polyglot Architecture)

| Service | Language | Framework | Port | Database |
|---------|----------|-----------|------|----------|
| **API Gateway** | Node.js | Express | 9000 | - |
| **Auth Service** | Java 17 | Spring Boot 3.2 | 8080 | PostgreSQL |
| **Search Service** | Go 1.21 | Gin | 8081 | MongoDB |
| **Booking Service** | Python 3.11 | FastAPI | 8000 | PostgreSQL |
| **Payment Service** | Go 1.21 | Gin | 8082 | PostgreSQL |
| **Notification Service** | Python 3.11 | FastAPI | 8083 | - |
| **Inventory Service** | Java 17 | Spring Boot 3.2 | 8085 | PostgreSQL |
| **Pricing Service** | Java 17 | Spring Boot 3.2 | 8087 | PostgreSQL |

### Infrastructure Components

- **Message Brokers**: Kafka (Bitnami), RabbitMQ
- **Databases**: PostgreSQL, MongoDB, Redis
- **Observability**: Prometheus, Loki, Grafana, Jaeger
- **Ingress**: Nginx Ingress Controller

---

## 📦 Prerequisites

### Ubuntu VM Requirements

#### 1. System Packages

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    jq \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common
```

## 🔨 Building Docker Images

### Prerequisites for Building

```bash
# Ensure Docker Buildx is available
docker buildx version


### Build All Services

#### Option 1: Build and Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Build and push all services
cd ReservationSystem

# API Gateway (Node.js)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-gateway:latest \
  -t ${DOCKER_USERNAME}/hotel-gateway:v1.0.0 \
  --push \
  ./gateway

# Auth Service (Java)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-auth-service:latest \
  -t ${DOCKER_USERNAME}/hotel-auth-service:v1.0.0 \
  --push \
  ./services/auth-service

# Search Service (Go)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-search-service:latest \
  -t ${DOCKER_USERNAME}/hotel-search-service:v1.0.0 \
  --push \
  ./services/search-service

# Booking Service (Python)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-booking-service:latest \
  -t ${DOCKER_USERNAME}/hotel-booking-service:v1.0.0 \
  --push \
  ./services/booking-service

# Payment Service (Go)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-payment-service:latest \
  -t ${DOCKER_USERNAME}/hotel-payment-service:v1.0.0 \
  --push \
  ./services/payment-service

# Notification Service (Python)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-notification-service:latest \
  -t ${DOCKER_USERNAME}/hotel-notification-service:v1.0.0 \
  --push \
  ./services/notification-service

# Inventory Service (Java)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-inventory-service:latest \
  -t ${DOCKER_USERNAME}/hotel-inventory-service:v1.0.0 \
  --push \
  ./services/inventory-service

# Pricing Service (Java)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-pricing-service:latest \
  -t ${DOCKER_USERNAME}/hotel-pricing-service:v1.0.0 \
  --push \
  ./services/pricing-service
```

## 🚀 Deploying to Kubernetes

### Step 1: Configure Helm Values

Edit `helm/hotel-reservation-system/values.yaml`:

```yaml
global:
  namespace: hotel-reservation
  imageRegistry: docker.io
  imageRepository: amansingh2708  # Change to your Docker Hub username
  imageTag: latest
  imagePullPolicy: Always
```

### Step 2: Deploy the Application

```bash
cd ReservationSystem

# Install/Upgrade the Helm chart
helm upgrade --install hotel-reservation \
  ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --create-namespace \
  --timeout 10m \
  --wait

# Watch pods starting up
kubectl get pods -n hotel-reservation -w
```

## 🌐 Accessing Services

### Frontend Application (via Nginx Ingress)

The frontend application is exposed through Nginx Ingress Controller.

```bash
# Get LoadBalancer IP
export NGINX_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Nginx Ingress IP: $NGINX_IP"

# Access frontend
echo "Frontend URL: http://$NGINX_IP"
```

Open your browser and navigate to: **`http://$NGINX_IP`**

---

### Observability Stack (via Port-Forward)

All observability services are accessed using `kubectl port-forward`:

#### 1. Grafana (Dashboards & Visualization)

```bash
# Port-forward Grafana
kubectl port-forward -n hotel-reservation svc/grafana 3000:3000

# Access in browser: http://localhost:3000
# Username: admin
# Password: admin123
```

**Available Dashboards:**
- Application Logs - Real-time logs from all services
- Service Overview - Request rates, latency, error rates
- Individual Services - Per-service metrics
- Kafka Dashboard - Message broker metrics
- Cluster Overview - Kubernetes cluster health
- Business Metrics - Booking rates, revenue

#### 2. Prometheus (Metrics)

```bash
# Port-forward Prometheus
kubectl port-forward -n hotel-reservation svc/prometheus 9090:9090

# Access in browser: http://localhost:9090
```

**Example Queries:**
```promql
# Request rate per service
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

#### 3. Jaeger (Distributed Tracing)

```bash
# Port-forward Jaeger
kubectl port-forward -n hotel-reservation svc/jaeger-query 16686:16686

# Access in browser: http://localhost:16686
```

View distributed traces across all microservices to debug latency and errors.

#### 4. Loki (Log Aggregation)

Loki is accessed through Grafana's Explore feature.

```bash
# Port-forward Grafana (if not already running)
kubectl port-forward -n hotel-reservation svc/grafana 3000:3000

# In Grafana:
# 1. Go to Explore (compass icon)
# 2. Select "Loki" data source
# 3. Use LogQL queries
```

**Example LogQL Queries:**
```logql
# All logs from booking service
{namespace="hotel-reservation", container="booking-service"}

# Error logs from all services
{namespace="hotel-reservation"} |~ "(?i)(error|exception|failed)"

# Kafka events
{namespace="hotel-reservation", container="booking-service"} |~ "kafka"
```

---

### API Gateway (Optional - for Testing)

The API Gateway is typically accessed through the frontend, but you can also access it directly for testing:

```bash
# Port-forward API Gateway
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000

# Test endpoints
curl http://localhost:9000/health
curl http://localhost:9000/api/search/hotels?city=Mumbai&checkIn=2024-12-01&checkOut=2024-12-05
```

---

### Quick Access Summary

| Service | Access Method | URL | Credentials |
|---------|---------------|-----|-------------|
| **Frontend** | Nginx Ingress | `http://$NGINX_IP` | - |
| **Grafana** | Port-forward | `http://localhost:3000` | admin / admin123 |
| **Prometheus** | Port-forward | `http://localhost:9090` | - |
| **Jaeger** | Port-forward | `http://localhost:16686` | - |
| **API Gateway** | Port-forward | `http://localhost:9000` | - |

---

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n hotel-reservation

# Describe pod for events
kubectl describe pod <pod-name> -n hotel-reservation

# Check logs
kubectl logs <pod-name> -n hotel-reservation
```

### Image Pull Errors

```bash
# Verify image exists
docker pull amansingh2708/hotel-gateway:latest

# Check imagePullPolicy in values.yaml
# Set to "IfNotPresent" for local images
```

### Logs Not Appearing in Grafana

```bash
# Check Promtail is running
kubectl get pods -n hotel-reservation -l app.kubernetes.io/name=promtail

# Check Loki is ready
kubectl get pods -n hotel-reservation -l app.kubernetes.io/name=loki

# Restart Promtail
kubectl rollout restart daemonset/promtail -n hotel-reservation

# Verify logs in Loki
kubectl exec -n hotel-reservation loki-0 -- wget -qO- \
  'http://localhost:3100/loki/api/v1/label/namespace/values' 2>/dev/null
```

### Port-Forward Connection Issues

```bash
# If port-forward disconnects, restart it
# Kill existing port-forward
pkill -f "port-forward"

# Start new port-forward
kubectl port-forward -n hotel-reservation svc/grafana 3000:3000
```

### Database Connection Issues

```bash
# Check database pods
kubectl get pods -n hotel-reservation | grep -E "(postgres|mongo|redis)"

# Check service endpoints
kubectl get endpoints -n hotel-reservation | grep -E "(postgres|mongo|redis)"

# Test connection from service pod
kubectl exec -it <service-pod> -n hotel-reservation -- nc -zv postgresql 5432
```

---

## 🧹 Cleanup

```bash
# Delete the application
helm uninstall hotel-reservation -n hotel-reservation

# Delete namespace
kubectl delete namespace hotel-reservation

```

---
