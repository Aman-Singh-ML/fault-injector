# ⚡ Helm Quick Start - 5 Minutes to Deploy

## 🎯 One-Command Deployment

```bash
# Make script executable (first time only)
chmod +x deploy-local.sh

# Deploy everything!
./deploy-local.sh
```

That's it! The script will:
1. ✅ Check prerequisites (Docker, kubectl, Helm, Minikube)
2. ✅ Start Minikube
3. ✅ Build all Docker images
4. ✅ Load images to Minikube
5. ✅ Deploy with Helm
6. ✅ Wait for all pods to be ready
7. ✅ Show you how to access the application

---

## 📋 Prerequisites

Install these tools first:

```bash
# macOS
brew install docker kubectl helm minikube

# Verify installations
docker --version
kubectl version --client
helm version
minikube version
```

---

## 🚀 Access Your Application

### Option 1: Minikube Service (Recommended)

```bash
minikube service gateway -n hotel-reservation
```

This will automatically open your browser!

### Option 2: Port Forwarding

```bash
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
```

Then open: **http://localhost:9000**

---

## 🗄️ Access Databases

### PostgreSQL (Auth Service)

```bash
kubectl exec -it -n hotel-reservation postgres-auth-0 -- psql -U auth_user -d auth_db
```

**Credentials:**
- Database: `auth_db`
- User: `auth_user`
- Password: `auth_pass`

### PostgreSQL (Booking Service)

```bash
kubectl exec -it -n hotel-reservation postgres-booking-0 -- psql -U booking_user -d booking_db
```

**Credentials:**
- Database: `booking_db`
- User: `booking_user`
- Password: `booking_pass`

### PostgreSQL (Payment Service)

```bash
kubectl exec -it -n hotel-reservation postgres-payment-0 -- psql -U payment_user -d payment_db
```

**Credentials:**
- Database: `payment_db`
- User: `payment_user`
- Password: `payment_pass`

### MongoDB (Search Service)

```bash
kubectl exec -it -n hotel-reservation mongo-search-0 -- mongosh -u search_user -p search_pass
```

**Credentials:**
- User: `search_user`
- Password: `search_pass`

### Redis

```bash
kubectl exec -it -n hotel-reservation $(kubectl get pod -n hotel-reservation -l app=redis -o jsonpath='{.items[0].metadata.name}') -- redis-cli
```

### RabbitMQ Management UI

```bash
kubectl port-forward -n hotel-reservation svc/rabbitmq 15672:15672
```

Open: **http://localhost:15672**
- Username: `admin`
- Password: `admin`

---

## 📊 Monitoring

### View All Pods

```bash
kubectl get pods -n hotel-reservation
```

### View Logs

```bash
# Auth Service
kubectl logs -n hotel-reservation -l app=auth-service -f

# Search Service
kubectl logs -n hotel-reservation -l app=search-service -f

# Booking Service
kubectl logs -n hotel-reservation -l app=booking-service -f

# Gateway
kubectl logs -n hotel-reservation -l app=gateway -f
```

### Check Service Status

```bash
kubectl get svc -n hotel-reservation
```

### Resource Usage

```bash
kubectl top pods -n hotel-reservation
```

---

## 🧪 Test the APIs

### Port Forward Gateway

```bash
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
```

### Register a User

```bash
curl -X POST http://localhost:9000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "phoneNumber": "+1234567890"
  }'
```

### Login

```bash
curl -X POST http://localhost:9000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Search Hotels

```bash
curl "http://localhost:9000/search?location=NewYork&checkIn=2024-01-15&checkOut=2024-01-20"
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

### Update Specific Service

```bash
# Rebuild specific service
cd services/auth-service
docker build -t auth-service:latest .
cd ../..

# Load to Minikube
minikube image load auth-service:latest

# Restart deployment
kubectl rollout restart deployment/auth-service -n hotel-reservation
```

---

## 🧹 Cleanup

### Uninstall Application

```bash
# Uninstall Helm release
helm uninstall hotel-reservation

# Delete namespace (removes all resources)
kubectl delete namespace hotel-reservation
```

### Stop Minikube

```bash
minikube stop
```

### Delete Minikube Cluster

```bash
minikube delete
```

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n hotel-reservation

# Describe problematic pod
kubectl describe pod -n hotel-reservation <pod-name>

# Check logs
kubectl logs -n hotel-reservation <pod-name>
```

### Image Pull Errors

```bash
# Verify images in Minikube
minikube image ls | grep -E "auth-service|search-service|booking-service"

# Reload image
minikube image load <image-name>:latest
```

### Service Not Accessible

```bash
# Check service
kubectl get svc -n hotel-reservation gateway

# Check endpoints
kubectl get endpoints -n hotel-reservation gateway

# Test with port forward
kubectl port-forward -n hotel-reservation svc/gateway 9000:9000
```

### Database Connection Issues

```bash
# Check database pods
kubectl get pods -n hotel-reservation | grep postgres

# Check database logs
kubectl logs -n hotel-reservation postgres-auth-0

# Test connection from service pod
kubectl exec -it -n hotel-reservation <service-pod> -- nc -zv postgres-auth 5432
```

---

## 📚 Architecture

### Independent Databases per Service

```
Auth Service      → postgres-auth (auth_db)
Search Service    → mongo-search (search_db)
Booking Service   → postgres-booking (booking_db)
Payment Service   → postgres-payment (payment_db)
```

### Shared Infrastructure

- **Redis** - Cache (shared by Search and Booking)
- **Kafka** - Event streaming (used by Booking)
- **RabbitMQ** - Message queue (used by Payment and Notification)

---

## ✅ Quick Reference

| Command | Description |
|---------|-------------|
| `./deploy-local.sh` | Deploy everything |
| `kubectl get pods -n hotel-reservation` | View all pods |
| `kubectl logs -n hotel-reservation -l app=<service> -f` | View logs |
| `kubectl port-forward -n hotel-reservation svc/gateway 9000:9000` | Access gateway |
| `helm uninstall hotel-reservation` | Uninstall |
| `minikube service gateway -n hotel-reservation` | Open gateway in browser |

---

## 🎉 You're Ready!

Your complete microservices system is now running on Kubernetes with:
- ✅ 6 Application services
- ✅ 3 PostgreSQL databases (one per service)
- ✅ 1 MongoDB database
- ✅ Redis cache
- ✅ Kafka event streaming
- ✅ RabbitMQ message queue

**Happy Coding! 🚀**

For detailed documentation, see: **HELM_DEPLOYMENT_GUIDE.md**

