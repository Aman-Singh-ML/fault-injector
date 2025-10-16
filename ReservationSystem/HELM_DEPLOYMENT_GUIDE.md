# 🚀 Helm Deployment Guide - Hotel Reservation System

## 📋 Prerequisites

### Required Tools
- **Docker** - For building images
- **kubectl** - Kubernetes CLI
- **Helm 3** - Package manager for Kubernetes
- **Minikube** or **Kind** - Local Kubernetes cluster

### Install Tools (macOS)

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install kubectl
brew install kubectl

# Install Helm
brew install helm

# Install Minikube
brew install minikube

# Or install Kind (alternative to Minikube)
brew install kind
```

---

## 🎯 Quick Start with Minikube

### Step 1: Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --disk-size=20g

# Verify Minikube is running
minikube status

# Enable metrics server (optional)
minikube addons enable metrics-server
```

### Step 2: Build Docker Images

```bash
# Make script executable
chmod +x build-images.sh

# Build all service images
./build-images.sh
```

This will build:
- ✅ auth-service:latest
- ✅ search-service:latest
- ✅ booking-service:latest
- ✅ payment-service:latest
- ✅ notification-service:latest
- ✅ gateway:latest

### Step 3: Load Images to Minikube

```bash
# Make script executable
chmod +x load-images-to-minikube.sh

# Load images to Minikube
./load-images-to-minikube.sh
```

### Step 4: Deploy with Helm

```bash
# Install the Helm chart
helm install hotel-reservation ./helm/hotel-reservation

# Or with custom namespace
helm install hotel-reservation ./helm/hotel-reservation --create-namespace
```

### Step 5: Verify Deployment

```bash
# Check all pods
kubectl get pods -n hotel-reservation

# Check all services
kubectl get svc -n hotel-reservation

# Check persistent volume claims
kubectl get pvc -n hotel-reservation

# Watch pod status
kubectl get pods -n hotel-reservation -w
```

### Step 6: Access the Application

```bash
# Get the Gateway URL
minikube service gateway -n hotel-reservation --url

# Or use port forwarding
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
```

Then access: **http://localhost:9000**

---

## 🎯 Quick Start with Kind

### Step 1: Create Kind Cluster

```bash
# Create cluster
kind create cluster --name hotel-reservation

# Verify cluster
kubectl cluster-info --context kind-hotel-reservation
```

### Step 2: Build and Load Images

```bash
# Build images
./build-images.sh

# Load images to Kind
kind load docker-image auth-service:latest --name hotel-reservation
kind load docker-image search-service:latest --name hotel-reservation
kind load docker-image booking-service:latest --name hotel-reservation
kind load docker-image payment-service:latest --name hotel-reservation
kind load docker-image notification-service:latest --name hotel-reservation
kind load docker-image gateway:latest --name hotel-reservation
```

### Step 3: Deploy with Helm

```bash
# Install the Helm chart
helm install hotel-reservation ./helm/hotel-reservation
```

### Step 4: Access the Application

```bash
# Port forward to access gateway
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
```

Access: **http://localhost:9000**

---

## 📊 Architecture Overview

### Database Architecture (Independent DBs per Service)

```
┌─────────────────┐     ┌──────────────────┐
│  Auth Service   │────▶│  postgres-auth   │
└─────────────────┘     └──────────────────┘

┌─────────────────┐     ┌──────────────────┐
│ Search Service  │────▶│  mongo-search    │
└─────────────────┘     └──────────────────┘

┌─────────────────┐     ┌──────────────────┐
│ Booking Service │────▶│ postgres-booking │
└─────────────────┘     └──────────────────┘

┌─────────────────┐     ┌──────────────────┐
│ Payment Service │────▶│ postgres-payment │
└─────────────────┘     └──────────────────┘
```

### Shared Infrastructure

- **Redis** - Shared cache for Search and Booking services
- **Kafka** - Event streaming for Booking service
- **RabbitMQ** - Message queue for Payment and Notification services

---

## 🔧 Helm Commands

### Install/Upgrade

```bash
# Install
helm install hotel-reservation ./helm/hotel-reservation

# Upgrade
helm upgrade hotel-reservation ./helm/hotel-reservation

# Install or upgrade
helm upgrade --install hotel-reservation ./helm/hotel-reservation

# Dry run (test without installing)
helm install hotel-reservation ./helm/hotel-reservation --dry-run --debug
```

### Uninstall

```bash
# Uninstall release
helm uninstall hotel-reservation

# Uninstall and delete namespace
helm uninstall hotel-reservation
kubectl delete namespace hotel-reservation
```

### List and Status

```bash
# List all releases
helm list

# Get release status
helm status hotel-reservation

# Get release values
helm get values hotel-reservation

# Get release manifest
helm get manifest hotel-reservation
```

### Customize Values

```bash
# Install with custom values
helm install hotel-reservation ./helm/hotel-reservation \
  --set authService.replicaCount=2 \
  --set gateway.service.nodePort=30080

# Install with values file
helm install hotel-reservation ./helm/hotel-reservation \
  -f custom-values.yaml
```

---

## 🗄️ Database Access

### PostgreSQL (Auth Service)

```bash
# Connect to postgres-auth
kubectl exec -it -n hotel-reservation postgres-auth-0 -- psql -U auth_user -d auth_db

# Port forward
kubectl port-forward -n hotel-reservation svc/postgres-auth 5432:5432

# Connect from local machine
psql -h localhost -p 5432 -U auth_user -d auth_db
```

### PostgreSQL (Booking Service)

```bash
# Connect to postgres-booking
kubectl exec -it -n hotel-reservation postgres-booking-0 -- psql -U booking_user -d booking_db
```

### PostgreSQL (Payment Service)

```bash
# Connect to postgres-payment
kubectl exec -it -n hotel-reservation postgres-payment-0 -- psql -U payment_user -d payment_db
```

### MongoDB (Search Service)

```bash
# Connect to mongo-search
kubectl exec -it -n hotel-reservation mongo-search-0 -- mongosh -u search_user -p search_pass

# Port forward
kubectl port-forward -n hotel-reservation svc/mongo-search 27017:27017

# Connect from local machine
mongosh mongodb://search_user:search_pass@localhost:27017
```

### Redis

```bash
# Connect to Redis
kubectl exec -it -n hotel-reservation $(kubectl get pod -n hotel-reservation -l app=redis -o jsonpath='{.items[0].metadata.name}') -- redis-cli

# Port forward
kubectl port-forward -n hotel-reservation svc/redis 6379:6379
```

### RabbitMQ

```bash
# Access Management UI
kubectl port-forward -n hotel-reservation svc/rabbitmq 15672:15672

# Open in browser
http://localhost:15672
# Username: admin
# Password: admin
```

### Kafka

```bash
# List topics
kubectl exec -it -n hotel-reservation $(kubectl get pod -n hotel-reservation -l app=kafka -o jsonpath='{.items[0].metadata.name}') -- kafka-topics.sh --bootstrap-server localhost:9092 --list

# Create topic
kubectl exec -it -n hotel-reservation $(kubectl get pod -n hotel-reservation -l app=kafka -o jsonpath='{.items[0].metadata.name}') -- kafka-topics.sh --bootstrap-server localhost:9092 --create --topic booking-events --partitions 3 --replication-factor 1
```

---

## 📝 Monitoring and Debugging

### View Logs

```bash
# View logs for a specific service
kubectl logs -n hotel-reservation -l app=auth-service -f

# View logs for all services
kubectl logs -n hotel-reservation -l app --all-containers=true -f

# View logs for a specific pod
kubectl logs -n hotel-reservation <pod-name> -f
```

### Describe Resources

```bash
# Describe pod
kubectl describe pod -n hotel-reservation <pod-name>

# Describe service
kubectl describe svc -n hotel-reservation <service-name>

# Describe pvc
kubectl describe pvc -n hotel-reservation <pvc-name>
```

### Execute Commands in Pods

```bash
# Get shell access
kubectl exec -it -n hotel-reservation <pod-name> -- /bin/sh

# Run a command
kubectl exec -n hotel-reservation <pod-name> -- env
```

### Resource Usage

```bash
# Get resource usage
kubectl top pods -n hotel-reservation
kubectl top nodes

# Get all resources
kubectl get all -n hotel-reservation
```

---

## 🧪 Testing the Deployment

### Health Checks

```bash
# Port forward gateway
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000

# Test services
curl http://localhost:9000/auth/health
curl http://localhost:9000/search/health
curl http://localhost:9000/booking/health
curl http://localhost:9000/payment/health
curl http://localhost:9000/notify/health
```

### API Testing

```bash
# Register user
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'

# Login
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

---

## 🔄 Update and Rollback

### Update Deployment

```bash
# Update image
kubectl set image deployment/auth-service -n hotel-reservation auth-service=auth-service:v2

# Rollout status
kubectl rollout status deployment/auth-service -n hotel-reservation

# Rollout history
kubectl rollout history deployment/auth-service -n hotel-reservation
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/auth-service -n hotel-reservation

# Rollback to specific revision
kubectl rollout undo deployment/auth-service -n hotel-reservation --to-revision=2
```

---

## 🧹 Cleanup

### Delete Everything

```bash
# Uninstall Helm release
helm uninstall hotel-reservation

# Delete namespace
kubectl delete namespace hotel-reservation

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete

# Or delete Kind cluster
kind delete cluster --name hotel-reservation
```

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n hotel-reservation

# Describe pod
kubectl describe pod -n hotel-reservation <pod-name>

# Check events
kubectl get events -n hotel-reservation --sort-by='.lastTimestamp'
```

### Image Pull Errors

```bash
# Verify images are loaded
minikube image ls | grep -E "auth-service|search-service|booking-service"

# Reload image
minikube image load <image-name>:latest
```

### Database Connection Issues

```bash
# Check if database pods are running
kubectl get pods -n hotel-reservation | grep postgres

# Check database logs
kubectl logs -n hotel-reservation postgres-auth-0

# Test connection from service pod
kubectl exec -it -n hotel-reservation <service-pod> -- nc -zv postgres-auth 5432
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n hotel-reservation

# Check endpoints
kubectl get endpoints -n hotel-reservation

# Port forward to test
kubectl port-forward -n hotel-reservation svc/<service-name> <local-port>:<service-port>
```

---

## 📚 Additional Resources

- **Helm Documentation**: https://helm.sh/docs/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Minikube Documentation**: https://minikube.sigs.k8s.io/docs/
- **Kind Documentation**: https://kind.sigs.k8s.io/

---

## ✅ Deployment Checklist

- [ ] Docker installed and running
- [ ] kubectl installed
- [ ] Helm 3 installed
- [ ] Minikube/Kind installed
- [ ] Cluster started
- [ ] Images built: `./build-images.sh`
- [ ] Images loaded to cluster
- [ ] Helm chart installed: `helm install hotel-reservation ./helm/hotel-reservation`
- [ ] All pods running: `kubectl get pods -n hotel-reservation`
- [ ] Gateway accessible: `kubectl port-forward -n hotel-reservation svc/gateway 9000:9000`
- [ ] Services tested

---

**Happy Deploying! 🚀**

