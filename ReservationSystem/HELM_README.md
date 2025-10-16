# 🏨 Hotel Reservation System - Helm Deployment

## 🎯 Complete Kubernetes Deployment with Independent Databases

This Helm chart deploys a complete microservices-based hotel reservation system with **independent databases for each service**.

---

## ⚡ Quick Start (One Command!)

```bash
./deploy-local.sh
```

That's it! This will:
1. ✅ Check prerequisites
2. ✅ Start Minikube
3. ✅ Build all Docker images
4. ✅ Load images to Minikube
5. ✅ Deploy with Helm
6. ✅ Wait for all pods to be ready

---

## 📋 Prerequisites

```bash
# macOS - Install all tools
brew install docker kubectl helm minikube

# Verify installations
docker --version
kubectl version --client
helm version
minikube version
```

---

## 🏗️ Architecture

### Independent Databases per Service

```
┌─────────────────┐     ┌──────────────────┐
│  Auth Service   │────▶│  postgres-auth   │ (auth_db)
└─────────────────┘     └──────────────────┘

┌─────────────────┐     ┌──────────────────┐
│ Search Service  │────▶│  mongo-search    │ (search_db)
└─────────────────┘     └──────────────────┘

┌─────────────────┐     ┌──────────────────┐
│ Booking Service │────▶│ postgres-booking │ (booking_db)
└─────────────────┘     └──────────────────┘

┌─────────────────┐     ┌──────────────────┐
│ Payment Service │────▶│ postgres-payment │ (payment_db)
└─────────────────┘     └──────────────────┘
```

### Shared Infrastructure

- **Redis** - Cache (Search & Booking services)
- **Kafka** - Event streaming (Booking service)
- **RabbitMQ** - Message queue (Payment & Notification services)

---

## 📦 What Gets Deployed

### Infrastructure (8 components):
1. PostgreSQL for Auth Service
2. PostgreSQL for Booking Service
3. PostgreSQL for Payment Service
4. MongoDB for Search Service
5. Redis
6. Zookeeper
7. Kafka
8. RabbitMQ

### Application Services (6 services):
1. Auth Service (Java/Spring Boot) - Port 8080
2. Search Service (Go) - Port 8081
3. Booking Service (Python/FastAPI) - Port 8000
4. Payment Service (Go) - Port 8082
5. Notification Service (Python/FastAPI) - Port 8083
6. API Gateway (Node.js) - Port 9000

**Total: 14 deployments**

---

## 🚀 Deployment Steps

### Option 1: Automated (Recommended)

```bash
# One command deployment
./deploy-local.sh
```

### Option 2: Manual

```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192

# 2. Build images
./build-images.sh

# 3. Load images to Minikube
./load-images-to-minikube.sh

# 4. Deploy with Helm
helm install hotel-reservation ./helm/hotel-reservation

# 5. Wait for pods
kubectl get pods -n hotel-reservation -w
```

---

## 🌐 Access the Application

### Option 1: Minikube Service

```bash
minikube service gateway -n hotel-reservation
```

### Option 2: Port Forwarding

```bash
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
```

Then open: **http://localhost:9000**

---

## 🗄️ Database Access

### PostgreSQL Databases

```bash
# Auth Service DB
kubectl exec -it -n hotel-reservation postgres-auth-0 -- psql -U auth_user -d auth_db

# Booking Service DB
kubectl exec -it -n hotel-reservation postgres-booking-0 -- psql -U booking_user -d booking_db

# Payment Service DB
kubectl exec -it -n hotel-reservation postgres-payment-0 -- psql -U payment_user -d payment_db
```

### MongoDB

```bash
kubectl exec -it -n hotel-reservation mongo-search-0 -- mongosh -u search_user -p search_pass
```

### Redis

```bash
kubectl exec -it -n hotel-reservation $(kubectl get pod -n hotel-reservation -l app=redis -o jsonpath='{.items[0].metadata.name}') -- redis-cli
```

### RabbitMQ Management UI

```bash
kubectl port-forward -n hotel-reservation svc/rabbitmq 15672:15672
```

Open: **http://localhost:15672** (admin/admin)

---

## 🧪 Test the APIs

```bash
# Port forward gateway
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000

# Register user
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User"}'

# Login
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Search hotels
curl "http://localhost:9000/search?location=NewYork"
```

---

## 📊 Monitoring

### View All Pods

```bash
kubectl get pods -n hotel-reservation
```

### View Logs

```bash
# Specific service
kubectl logs -n hotel-reservation -l app=auth-service -f

# All services
kubectl logs -n hotel-reservation --all-containers=true -f
```

### Resource Usage

```bash
kubectl top pods -n hotel-reservation
kubectl top nodes
```

---

## 🔄 Update Deployment

### Rebuild and Redeploy

```bash
# Rebuild images
./build-images.sh

# Load to Minikube
./load-images-to-minikube.sh

# Upgrade Helm release
helm upgrade hotel-reservation ./helm/hotel-reservation

# Restart deployments
kubectl rollout restart deployment -n hotel-reservation
```

---

## 🧹 Cleanup

```bash
# Uninstall Helm release
helm uninstall hotel-reservation

# Delete namespace
kubectl delete namespace hotel-reservation

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

---

## 📚 Documentation

| File | Description |
|------|-------------|
| **HELM_QUICK_START.md** | 5-minute quick start guide |
| **HELM_DEPLOYMENT_GUIDE.md** | Complete deployment guide with troubleshooting |
| **HELM_DEPLOYMENT_SUMMARY.md** | Overview of what was created |
| **HELM_README.md** | This file |

---

## 🔧 Helm Chart Configuration

### Default Values

```yaml
# Namespace
global.namespace: hotel-reservation

# Storage
global.storageClass: standard

# Service Replicas
authService.replicaCount: 1
searchService.replicaCount: 1
bookingService.replicaCount: 1
paymentService.replicaCount: 1
notificationService.replicaCount: 1
gateway.replicaCount: 1
```

### Customize Deployment

```bash
# Change replica count
helm install hotel-reservation ./helm/hotel-reservation \
  --set authService.replicaCount=2

# Change gateway NodePort
helm install hotel-reservation ./helm/hotel-reservation \
  --set gateway.service.nodePort=30080

# Use custom values file
helm install hotel-reservation ./helm/hotel-reservation \
  -f custom-values.yaml
```

---

## 🗄️ Database Credentials

| Service | Database | User | Password |
|---------|----------|------|----------|
| Auth | postgres-auth:5432/auth_db | auth_user | auth_pass |
| Booking | postgres-booking:5432/booking_db | booking_user | booking_pass |
| Payment | postgres-payment:5432/payment_db | payment_user | payment_pass |
| Search | mongo-search:27017 | search_user | search_pass |
| RabbitMQ | rabbitmq:5672 | admin | admin |

---

## 🎯 Key Features

✅ **Independent Databases** - Each service has its own database  
✅ **Persistent Storage** - Data survives pod restarts  
✅ **Health Checks** - Automatic monitoring  
✅ **Resource Limits** - Prevents resource exhaustion  
✅ **Auto-scaling Ready** - Easy to scale services  
✅ **ConfigMaps** - Environment configuration  
✅ **One-Command Deployment** - Simple deployment script  

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
kubectl get pods -n hotel-reservation
kubectl describe pod -n hotel-reservation <pod-name>
kubectl logs -n hotel-reservation <pod-name>
```

### Image Pull Errors

```bash
# Verify images
minikube image ls | grep -E "auth-service|search-service"

# Reload image
minikube image load <image-name>:latest
```

### Service Not Accessible

```bash
kubectl get svc -n hotel-reservation
kubectl get endpoints -n hotel-reservation
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
```

---

## 📞 Support

For detailed documentation:
- **Quick Start**: See `HELM_QUICK_START.md`
- **Full Guide**: See `HELM_DEPLOYMENT_GUIDE.md`
- **Summary**: See `HELM_DEPLOYMENT_SUMMARY.md`

---

## ✅ Quick Reference

```bash
# Deploy
./deploy-local.sh

# Access
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000

# Monitor
kubectl get pods -n hotel-reservation
kubectl logs -n hotel-reservation -l app=<service> -f

# Database
kubectl exec -it -n hotel-reservation postgres-auth-0 -- psql -U auth_user -d auth_db

# Cleanup
helm uninstall hotel-reservation
kubectl delete namespace hotel-reservation
```

---

## 🎉 You're Ready!

Your complete microservices system with independent databases is ready to deploy!

**Run: `./deploy-local.sh` and you're done!** 🚀

---

**Happy Deploying!** 🎊

