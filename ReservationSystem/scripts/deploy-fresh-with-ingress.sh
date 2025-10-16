#!/bin/bash

# Fresh Hotel Reservation System Deployment with Nginx Ingress
# This script deploys the complete system from scratch using proper service endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-"hotel-reservation"}
RELEASE_NAME=${RELEASE_NAME:-"hotel-reservation"}
CHART_PATH=${CHART_PATH:-"helm/hotel-reservation-system"}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"amansingh2708"}

echo -e "${BLUE}🚀 Fresh Hotel Reservation System Deployment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}Using namespace: $NAMESPACE${NC}"
echo -e "${CYAN}Using registry: $DOCKER_REGISTRY${NC}"
echo ""

# Step 1: Clean up any existing deployment
echo -e "${YELLOW}🧹 Step 1: Cleaning up existing deployment...${NC}"
helm uninstall $RELEASE_NAME -n $NAMESPACE 2>/dev/null || echo "No existing release found"
kubectl delete namespace $NAMESPACE 2>/dev/null || echo "No existing namespace found"

# Wait for namespace deletion
echo -e "${BLUE}Waiting for namespace cleanup...${NC}"
while kubectl get namespace $NAMESPACE >/dev/null 2>&1; do
    echo "Waiting for namespace deletion..."
    sleep 5
done

# Step 2: Create namespace
echo -e "${YELLOW}📦 Step 2: Creating namespace...${NC}"
kubectl create namespace $NAMESPACE

# Step 3: Install Nginx Ingress Controller (if not already installed)
echo -e "${YELLOW}🌐 Step 3: Setting up Nginx Ingress Controller...${NC}"
if ! kubectl get ingressclass nginx >/dev/null 2>&1; then
    echo -e "${BLUE}Installing Nginx Ingress Controller...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    
    # Wait for ingress controller to be ready
    echo -e "${BLUE}Waiting for Nginx Ingress Controller to be ready...${NC}"
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
else
    echo -e "${GREEN}✅ Nginx Ingress Controller already installed${NC}"
fi

# Step 4: Build Docker images
echo -e "${YELLOW}🔨 Step 4: Building Docker images...${NC}"
if [ -f "scripts/build-images.sh" ]; then
    chmod +x scripts/build-images.sh
    ./scripts/build-images.sh
else
    echo -e "${RED}❌ build-images.sh not found${NC}"
    exit 1
fi

# Step 5: Push Docker images
echo -e "${YELLOW}📤 Step 5: Pushing Docker images...${NC}"
if [ -f "scripts/push-images.sh" ]; then
    chmod +x scripts/push-images.sh
    ./scripts/push-images.sh
else
    echo -e "${RED}❌ push-images.sh not found${NC}"
    exit 1
fi

# Step 6: Deploy with Helm
echo -e "${YELLOW}🚀 Step 6: Deploying with Helm...${NC}"
helm install $RELEASE_NAME $CHART_PATH -n $NAMESPACE --create-namespace

# Step 7: Wait for all pods to be ready
echo -e "${YELLOW}⏳ Step 7: Waiting for pods to be ready...${NC}"
echo -e "${BLUE}This may take 5-10 minutes...${NC}"

# Wait for all deployments to be ready
kubectl wait --for=condition=available deployment --all -n $NAMESPACE --timeout=600s

# Wait for all statefulsets to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=database -n $NAMESPACE --timeout=600s

echo -e "${GREEN}✅ All pods are ready${NC}"

# Step 8: Apply database schema fixes
echo -e "${YELLOW}🔧 Step 8: Applying database schema fixes...${NC}"
if [ -f "scripts/fix-booking-schema.sh" ]; then
    # Run only the database fix parts, not the full script
    kubectl exec -n $NAMESPACE statefulset/postgres-booking -- psql -U booking_user -d booking_db -c "
    ALTER TABLE bookings 
    ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'PENDING',
    ADD COLUMN IF NOT EXISTS payment_id INTEGER,
    ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(255);
    " || echo "Columns may already exist"
    
    kubectl exec -n $NAMESPACE statefulset/postgres-booking -- psql -U booking_user -d booking_db -c "
    CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON bookings(payment_status);
    CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
    CREATE INDEX IF NOT EXISTS idx_bookings_hotel_id ON bookings(hotel_id);
    CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
    CREATE INDEX IF NOT EXISTS idx_bookings_check_in_date ON bookings(check_in_date);
    CREATE INDEX IF NOT EXISTS idx_bookings_check_out_date ON bookings(check_out_date);
    "
    
    echo -e "${GREEN}✅ Database schema fixed${NC}"
else
    echo -e "${YELLOW}⚠️ fix-booking-schema.sh not found, skipping schema fixes${NC}"
fi

# Step 9: Populate databases with sample data
echo -e "${YELLOW}📊 Step 9: Populating databases with sample data...${NC}"
if [ -f "scripts/populate-dummy-data.sh" ]; then
    chmod +x scripts/populate-dummy-data.sh
    ./scripts/populate-dummy-data.sh
else
    echo -e "${RED}❌ populate-dummy-data.sh not found${NC}"
    exit 1
fi

# Step 10: Create Ingress resources
echo -e "${YELLOW}🌐 Step 10: Creating Ingress resources...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hotel-reservation-ingress
  namespace: $NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization"
spec:
  ingressClassName: nginx
  rules:
  - host: hotel-reservation.local
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: gateway
            port:
              number: 9000
      - path: /()(.*)
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 3000
EOF

echo -e "${GREEN}✅ Ingress resources created${NC}"

# Step 11: Get external access information
echo -e "${YELLOW}🔍 Step 11: Getting access information...${NC}"

# Get ingress external IP
EXTERNAL_IP=""
echo -e "${BLUE}Waiting for external IP assignment...${NC}"
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get ingress hotel-reservation-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get ingress hotel-reservation-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    fi
    if [ ! -z "$EXTERNAL_IP" ]; then
        break
    fi
    echo "Attempt $i/30: Waiting for external IP..."
    sleep 10
done

# Step 12: Test the deployment
echo -e "${YELLOW}🧪 Step 12: Testing deployment...${NC}"

# Test internal service communication
echo -e "${BLUE}Testing internal service endpoints...${NC}"
kubectl run test-pod --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
    curl -s -X GET http://gateway.${NAMESPACE}.svc.cluster.local:9000/health && echo " ✅ Gateway healthy" || echo " ❌ Gateway unhealthy"

kubectl run test-pod --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
    curl -s -X GET http://search-service.${NAMESPACE}.svc.cluster.local:8001/health && echo " ✅ Search service healthy" || echo " ❌ Search service unhealthy"

kubectl run test-pod --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
    curl -s -X GET http://booking-service.${NAMESPACE}.svc.cluster.local:8000/health && echo " ✅ Booking service healthy" || echo " ❌ Booking service unhealthy"

echo ""
echo -e "${GREEN}🎉 Fresh deployment completed successfully!${NC}"
echo ""
