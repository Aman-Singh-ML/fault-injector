#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Hotel Reservation System - Complete Local Deployment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found. Please install Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl found${NC}"

if ! command -v helm &> /dev/null; then
    echo -e "${RED}✗ Helm not found. Please install Helm first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Helm found${NC}"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}✗ Minikube not found. Please install Minikube first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Minikube found${NC}"

echo ""

# Step 2: Start Minikube
echo -e "${YELLOW}Step 2: Starting Minikube...${NC}"
if minikube status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Minikube is already running${NC}"
else
    echo -e "${YELLOW}Starting Minikube with 4 CPUs and 8GB RAM...${NC}"
    minikube start --cpus=4 --memory=8192 --disk-size=20g
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Minikube started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start Minikube${NC}"
        exit 1
    fi
fi
echo ""

# Step 3: Build Docker images
echo -e "${YELLOW}Step 3: Building Docker images...${NC}"
./build-images.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to build images${NC}"
    exit 1
fi
echo ""

# Step 4: Load images to Minikube
echo -e "${YELLOW}Step 4: Loading images to Minikube...${NC}"
./load-images-to-minikube.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to load images${NC}"
    exit 1
fi
echo ""

# Step 5: Deploy with Helm
echo -e "${YELLOW}Step 5: Deploying with Helm...${NC}"

# Check if release already exists
if helm list | grep -q hotel-reservation; then
    echo -e "${YELLOW}Upgrading existing release...${NC}"
    helm upgrade hotel-reservation ./helm/hotel-reservation
else
    echo -e "${YELLOW}Installing new release...${NC}"
    helm install hotel-reservation ./helm/hotel-reservation
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Helm deployment successful${NC}"
else
    echo -e "${RED}✗ Helm deployment failed${NC}"
    exit 1
fi
echo ""

# Step 6: Wait for pods to be ready
echo -e "${YELLOW}Step 6: Waiting for pods to be ready...${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres-auth -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres-booking -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres-payment -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=mongo-search -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=zookeeper -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=kafka -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n hotel-reservation --timeout=300s

echo -e "${GREEN}✓ Infrastructure pods are ready${NC}"
echo ""

# Wait for application services
kubectl wait --for=condition=ready pod -l app=auth-service -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=search-service -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=booking-service -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=payment-service -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=notification-service -n hotel-reservation --timeout=300s
kubectl wait --for=condition=ready pod -l app=gateway -n hotel-reservation --timeout=300s

echo -e "${GREEN}✓ All application pods are ready${NC}"
echo ""

# Step 7: Display deployment info
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Deployment Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📊 Deployment Status:${NC}"
kubectl get pods -n hotel-reservation
echo ""

echo -e "${BLUE}🌐 Services:${NC}"
kubectl get svc -n hotel-reservation
echo ""

echo -e "${BLUE}💾 Persistent Volume Claims:${NC}"
kubectl get pvc -n hotel-reservation
echo ""

echo -e "${YELLOW}🚀 Access the Application:${NC}"
echo ""
echo -e "  ${GREEN}Option 1: Using Minikube service${NC}"
echo -e "    minikube service gateway -n hotel-reservation"
echo ""
echo -e "  ${GREEN}Option 2: Using port forwarding${NC}"
echo -e "    kubectl port-forward -n hotel-reservation svc/gateway 9000:9000"
echo -e "    Then access: ${BLUE}http://localhost:9000${NC}"
echo ""

echo -e "${YELLOW}📝 Useful Commands:${NC}"
echo ""
echo -e "  ${GREEN}View logs:${NC}"
echo -e "    kubectl logs -n hotel-reservation -l app=auth-service -f"
echo ""
echo -e "  ${GREEN}Access database:${NC}"
echo -e "    kubectl exec -it -n hotel-reservation postgres-auth-0 -- psql -U auth_user -d auth_db"
echo ""
echo -e "  ${GREEN}RabbitMQ Management UI:${NC}"
echo -e "    kubectl port-forward -n hotel-reservation svc/rabbitmq 15672:15672"
echo -e "    Then access: ${BLUE}http://localhost:15672${NC} (admin/admin)"
echo ""
echo -e "  ${GREEN}Uninstall:${NC}"
echo -e "    helm uninstall hotel-reservation"
echo -e "    kubectl delete namespace hotel-reservation"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Happy Testing! 🎉${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

