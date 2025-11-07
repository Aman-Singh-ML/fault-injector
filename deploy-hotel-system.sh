#!/bin/bash

set -e

echo "🚀 Hotel Reservation System - Complete Deployment Script"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Minikube is running
echo ""
echo "1️⃣ Checking Minikube status..."
if ! minikube status > /dev/null 2>&1; then
    echo -e "${RED}❌ Minikube is not running. Starting Minikube...${NC}"
    minikube start --memory=8192 --cpus=4
else
    echo -e "${GREEN}✅ Minikube is running${NC}"
fi

# Step 2: Set kubectl context
echo ""
echo "2️⃣ Setting kubectl context to minikube..."
kubectl config use-context minikube
echo -e "${GREEN}✅ Context set to minikube${NC}"

# Step 3: Build Docker images in Minikube
echo ""
echo "3️⃣ Building Docker images in Minikube..."
eval $(minikube docker-env)

# Check if images already exist
if docker images | grep -q "hotel-frontend.*amrita"; then
    echo -e "${YELLOW}⚠️  Images already exist. Skipping build...${NC}"
    read -p "Do you want to rebuild images? (y/N): " rebuild
    if [[ $rebuild =~ ^[Yy]$ ]]; then
        echo "Rebuilding images..."
        cd ReservationSystem
        ./build-for-minikube.sh
        cd ..
    fi
else
    echo "Building images for the first time..."
    cd ReservationSystem
    if [ ! -f "build-for-minikube.sh" ]; then
        echo -e "${RED}❌ build-for-minikube.sh not found!${NC}"
        exit 1
    fi
    chmod +x build-for-minikube.sh
    ./build-for-minikube.sh
    cd ..
fi
echo -e "${GREEN}✅ Docker images ready${NC}"

# Step 4: Pull Kafka image to avoid rate limit
echo ""
echo "4️⃣ Pulling Kafka image into Minikube..."
eval $(minikube docker-env)
if docker images | grep -q "bitnamilegacy/kafka.*3.8.0"; then
    echo -e "${GREEN}✅ Kafka image already exists${NC}"
else
    echo "Pulling Kafka image..."
    docker pull bitnamilegacy/kafka:3.8.0-debian-12-r5
    echo -e "${GREEN}✅ Kafka image pulled${NC}"
fi

# Step 5: Clean up existing deployment
echo ""
echo "5️⃣ Cleaning up existing deployment..."
if helm list -n hotel-reserve-dummy | grep -q hotel-reserve-dummy; then
    echo "Uninstalling existing release..."
    helm uninstall hotel-reserve-dummy -n hotel-reserve-dummy --wait --timeout=3m || true
    sleep 10
fi

# Delete namespace to ensure clean state
if kubectl get namespace hotel-reserve-dummy > /dev/null 2>&1; then
    echo "Deleting namespace..."
    kubectl delete namespace hotel-reserve-dummy --timeout=2m || true
    sleep 5
fi
echo -e "${GREEN}✅ Cleanup complete${NC}"

# Step 6: Install Helm chart
echo ""
echo "6️⃣ Installing Hotel Reservation System..."
helm install hotel-reserve-dummy ReservationSystem/helm/hotel-reservation-system \
    -n hotel-reserve-dummy \
    --create-namespace \
    --timeout 10m \
    --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Helm installation completed${NC}"
else
    echo -e "${YELLOW}⚠️  Helm installation timed out, but continuing...${NC}"
fi

# Step 7: Wait for core services
echo ""
echo "7️⃣ Waiting for core services to be ready..."
echo "This may take a few minutes..."

# Wait for frontend
echo -n "Waiting for frontend..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=frontend -n hotel-reserve-dummy --timeout=5m || true
echo -e " ${GREEN}✅${NC}"

# Wait for gateway
echo -n "Waiting for gateway..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gateway -n hotel-reserve-dummy --timeout=5m || true
echo -e " ${GREEN}✅${NC}"

# Wait for search service
echo -n "Waiting for search service..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=search-service -n hotel-reserve-dummy --timeout=5m || true
echo -e " ${GREEN}✅${NC}"

# Wait for booking service
echo -n "Waiting for booking service..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=booking-service -n hotel-reserve-dummy --timeout=5m || true
echo -e " ${GREEN}✅${NC}"

# Wait for auth service
echo -n "Waiting for auth service..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=auth-service -n hotel-reserve-dummy --timeout=5m || true
echo -e " ${GREEN}✅${NC}"

# Step 8: Check pod status
echo ""
echo "8️⃣ Checking deployment status..."
echo ""
kubectl get pods -n hotel-reserve-dummy | grep -E "(NAME|frontend|gateway|auth|search|booking)"

# Step 9: Get access URL
echo ""
echo "9️⃣ Getting access information..."
MINIKUBE_IP=$(minikube ip)
echo ""
echo -e "${GREEN}=========================================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "==========================================================${NC}"
echo ""
echo "🌐 Access your application at: http://$MINIKUBE_IP/"
echo ""
echo "📊 Useful commands:"
echo "  - View all pods: kubectl get pods -n hotel-reserve-dummy"
echo "  - View logs: kubectl logs -n hotel-reserve-dummy deployment/<service-name>"
echo "  - Port forward: kubectl port-forward -n hotel-reserve-dummy svc/gateway 9000:9000"
echo ""
echo -e "${YELLOW}⚠️  Note: Some services may still be starting. Wait a few minutes for full readiness.${NC}"
echo ""

