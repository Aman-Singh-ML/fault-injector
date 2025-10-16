# 🚀 Kubernetes Deployment Guide - Hotel Reservation System

**Last Updated**: 2025-10-14  
**Status**: ✅ Ready for Deployment

---

## 📋 **Prerequisites**

Before deploying to Kubernetes, ensure you have the following installed:

### **Required Tools**:
- ✅ **Docker Desktop** (with Kubernetes enabled) OR **Minikube**
- ✅ **kubectl** (Kubernetes CLI)
- ✅ **Helm** (v3.0+)
- ✅ **Git** (for cloning the repository)

### **System Requirements**:
- **RAM**: Minimum 8GB (16GB recommended)
- **CPU**: Minimum 4 cores
- **Disk**: Minimum 20GB free space

---

## 🔧 **Installation Steps**

### **1. Install Docker Desktop**

**macOS**:
```bash
brew install --cask docker
```

**Windows/Linux**: Download from [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)

**Enable Kubernetes in Docker Desktop**:
1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"

### **2. Install kubectl**

**macOS**:
```bash
brew install kubectl
```

**Windows**:
```bash
choco install kubernetes-cli
```

**Linux**:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Verify Installation**:
```bash
kubectl version --client
```

### **3. Install Helm**

**macOS**:
```bash
brew install helm
```

**Windows**:
```bash
choco install kubernetes-helm
```

**Linux**:
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Verify Installation**:
```bash
helm version
```

---

## 🚀 **Quick Deployment**

### **Option 1: Automated Deployment (Recommended)**

```bash
# Make scripts executable
chmod +x deploy-to-kubernetes.sh test-kubernetes-deployment.sh

# Deploy to Kubernetes
./deploy-to-kubernetes.sh

# Test the deployment
./test-kubernetes-deployment.sh
```

### **Option 2: Manual Deployment**

```bash
# Step 1: Build Docker images
docker build -t gateway:latest ./gateway
docker build -t search-service:latest ./services/search-service
docker build -t booking-service:latest ./services/booking-service
docker build -t payment-service:latest ./services/payment-service
docker build -t notification-service:latest ./services/notification-service

# Step 2: Create namespace
kubectl create namespace hotel-reservation

# Step 3: Deploy with Helm
helm install hotel-reservation ./helm/hotel-reservation \
  --namespace hotel-reservation \
  --create-namespace \
  --wait \
  --timeout 10m

# Step 4: Check status
kubectl get pods -n hotel-reservation
kubectl get svc -n hotel-reservation
```

---

## 📊 **Deployment Architecture**

### **Kubernetes Resources Created**:

| Resource Type | Name | Purpose |
|---------------|------|---------|
| **Namespace** | hotel-reservation | Isolates all resources |
| **Deployments** | gateway, search-service, booking-service, payment-service, notification-service | Microservices |
| **StatefulSets** | postgres-auth, postgres-booking, postgres-payment, mongo-search, redis, kafka, zookeeper, rabbitmq | Stateful services |
| **Services** | ClusterIP for internal, NodePort for gateway | Service discovery |
| **ConfigMaps** | Service configurations | Environment variables |
| **Secrets** | Database credentials | Sensitive data |
| **PVCs** | Persistent storage for databases | Data persistence |

### **Services Deployed**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Namespace: hotel-reservation                         │  │
│  │                                                        │  │
│  │  Microservices:                                       │  │
│  │  • Gateway (NodePort 30900)                           │  │
│  │  • Search Service (ClusterIP)                         │  │
│  │  • Booking Service (ClusterIP)                        │  │
│  │  • Payment Service (ClusterIP)                        │  │
│  │  • Notification Service (ClusterIP)                   │  │
│  │                                                        │  │
│  │  Databases:                                           │  │
│  │  • PostgreSQL Auth (StatefulSet)                      │  │
│  │  • PostgreSQL Booking (StatefulSet)                   │  │
│  │  • PostgreSQL Payment (StatefulSet)                   │  │
│  │  • MongoDB (StatefulSet)                              │  │
│  │                                                        │  │
│  │  Infrastructure:                                      │  │
│  │  • Redis (StatefulSet)                                │  │
│  │  • Kafka (StatefulSet)                                │  │
│  │  • Zookeeper (StatefulSet)                            │  │
│  │  • RabbitMQ (StatefulSet)                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🌐 **Accessing the Application**

### **Method 1: NodePort (Default)**

The Gateway service is exposed via NodePort on port 30900:

```bash
# Get the NodePort
kubectl get svc gateway -n hotel-reservation

# Access the application
curl http://localhost:30900/health
```

**API Gateway URL**: `http://localhost:30900`

### **Method 2: Port Forwarding**

```bash
# Forward local port 9000 to gateway service
kubectl port-forward svc/gateway 9000:9000 -n hotel-reservation

# Access the application
curl http://localhost:9000/health
```

**API Gateway URL**: `http://localhost:9000`

### **Method 3: LoadBalancer (Cloud Only)**

If deploying to a cloud provider (AWS, GCP, Azure), change the gateway service type to LoadBalancer:

```bash
kubectl patch svc gateway -n hotel-reservation -p '{"spec":{"type":"LoadBalancer"}}'

# Get the external IP
kubectl get svc gateway -n hotel-reservation
```

---

## 🧪 **Testing the Deployment**

### **Automated Testing**:

```bash
./test-kubernetes-deployment.sh
```

### **Manual Testing**:

```bash
# Get Gateway URL
GATEWAY_URL="http://localhost:30900"

# Test 1: Health Check
curl $GATEWAY_URL/health

# Test 2: Login
TOKEN=$(curl -s -X POST $GATEWAY_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@a.com","password":"123456"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")

# Test 3: Search Hotels
curl -s -X GET "$GATEWAY_URL/search/hotels" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Test 4: Create Booking
curl -s -X POST $GATEWAY_URL/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "3",
    "hotelId": "hotel_001",
    "hotelName": "Grand Plaza Hotel",
    "checkInDate": "2025-12-25",
    "checkOutDate": "2025-12-27",
    "rooms": 1,
    "adults": 2,
    "children": 0,
    "totalPrice": 500
  }' | python3 -m json.tool
```

---

## 📝 **Useful Commands**

### **View Resources**:

```bash
# View all pods
kubectl get pods -n hotel-reservation

# View all services
kubectl get svc -n hotel-reservation

# View all persistent volume claims
kubectl get pvc -n hotel-reservation

# View all resources
kubectl get all -n hotel-reservation
```

### **View Logs**:

```bash
# View logs for a specific pod
kubectl logs -f <pod-name> -n hotel-reservation

# View logs for gateway
kubectl logs -f deployment/gateway -n hotel-reservation

# View logs for booking service
kubectl logs -f deployment/booking-service -n hotel-reservation
```

### **Debugging**:

```bash
# Describe a pod
kubectl describe pod <pod-name> -n hotel-reservation

# Execute command in a pod
kubectl exec -it <pod-name> -n hotel-reservation -- /bin/sh

# Check pod events
kubectl get events -n hotel-reservation --sort-by='.lastTimestamp'
```

### **Scaling**:

```bash
# Scale a deployment
kubectl scale deployment gateway --replicas=3 -n hotel-reservation

# Check horizontal pod autoscaler
kubectl get hpa -n hotel-reservation
```

---

## 🔄 **Updating the Deployment**

### **Update Application Code**:

```bash
# Rebuild Docker image
docker build -t gateway:latest ./gateway

# Restart deployment to use new image
kubectl rollout restart deployment/gateway -n hotel-reservation

# Check rollout status
kubectl rollout status deployment/gateway -n hotel-reservation
```

### **Update Helm Values**:

```bash
# Edit values.yaml
vim helm/hotel-reservation/values.yaml

# Upgrade Helm release
helm upgrade hotel-reservation ./helm/hotel-reservation \
  --namespace hotel-reservation \
  --wait

# Check upgrade status
helm status hotel-reservation -n hotel-reservation
```

---

## 🗑️ **Cleanup**

### **Delete Deployment**:

```bash
# Uninstall Helm release
helm uninstall hotel-reservation -n hotel-reservation

# Delete namespace (this will delete all resources)
kubectl delete namespace hotel-reservation

# Verify deletion
kubectl get all -n hotel-reservation
```

### **Delete Persistent Volumes**:

```bash
# List persistent volumes
kubectl get pv

# Delete specific PV
kubectl delete pv <pv-name>
```

---

## 🔍 **Troubleshooting**

### **Pods Not Starting**:

```bash
# Check pod status
kubectl get pods -n hotel-reservation

# Describe pod to see events
kubectl describe pod <pod-name> -n hotel-reservation

# Check logs
kubectl logs <pod-name> -n hotel-reservation
```

**Common Issues**:
- **ImagePullBackOff**: Docker image not found locally. Build images first.
- **CrashLoopBackOff**: Application crashing. Check logs for errors.
- **Pending**: Insufficient resources. Check node capacity.

### **Service Not Accessible**:

```bash
# Check service endpoints
kubectl get endpoints -n hotel-reservation

# Check if pods are ready
kubectl get pods -n hotel-reservation

# Test service from within cluster
kubectl run test-pod --rm -it --image=curlimages/curl -n hotel-reservation -- sh
# Inside pod: curl http://gateway:9000/health
```

### **Database Connection Issues**:

```bash
# Check if database pods are running
kubectl get pods -n hotel-reservation | grep postgres

# Check database logs
kubectl logs <postgres-pod-name> -n hotel-reservation

# Test database connection
kubectl exec -it <postgres-pod-name> -n hotel-reservation -- psql -U auth_user -d auth_db
```

---

## 📊 **Monitoring**

### **Resource Usage**:

```bash
# View resource usage
kubectl top pods -n hotel-reservation
kubectl top nodes

# View resource limits
kubectl describe pod <pod-name> -n hotel-reservation | grep -A 5 "Limits"
```

### **Health Checks**:

```bash
# Check all pod health
kubectl get pods -n hotel-reservation -o wide

# Check service health
for svc in gateway search-service booking-service payment-service notification-service; do
  echo "Checking $svc..."
  kubectl exec -it deployment/gateway -n hotel-reservation -- curl -s http://$svc:$(kubectl get svc $svc -n hotel-reservation -o jsonpath='{.spec.ports[0].port}')/health
done
```

---

## 🔐 **Security Considerations**

### **Secrets Management**:

Currently, secrets are stored in values.yaml. For production:

```bash
# Create Kubernetes secrets
kubectl create secret generic db-credentials \
  --from-literal=auth-password=<password> \
  --from-literal=booking-password=<password> \
  --from-literal=payment-password=<password> \
  -n hotel-reservation

# Update deployments to use secrets
# Edit helm templates to reference secrets instead of values
```

### **Network Policies**:

```bash
# Apply network policies to restrict traffic
kubectl apply -f network-policies.yaml -n hotel-reservation
```

---

## 📚 **Additional Resources**

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Helm Documentation**: https://helm.sh/docs/
- **Docker Documentation**: https://docs.docker.com/

---

**🎉 Your Hotel Reservation System is now running on Kubernetes!**

**Access Points**:
- API Gateway: `http://localhost:30900`
- Health Check: `http://localhost:30900/health`

**Login Credentials**:
- Customer: `a@a.com` / `123456`
- Admin: `admin@hotel.com` / `admin123`

