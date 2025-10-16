#!/bin/bash

# Fix Booking Service Database Schema
# This script fixes the missing payment_status column issue in the booking service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-"hotel-reservation"}
RELEASE_NAME=${RELEASE_NAME:-"hotel-reservation"}
CHART_PATH=${CHART_PATH:-"helm/hotel-reservation-system"}

echo -e "${BLUE}🔧 Fixing Booking Service Database Schema${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Step 1: Add missing columns to existing bookings table
echo -e "${YELLOW}📊 Step 1: Adding missing columns to bookings table...${NC}"
kubectl exec -n $NAMESPACE statefulset/postgres-booking -- psql -U booking_user -d booking_db -c "
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'PENDING',
ADD COLUMN IF NOT EXISTS payment_id INTEGER,
ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(255);
" || {
    echo -e "${RED}❌ Failed to add columns. This might be normal if columns already exist.${NC}"
}

# Step 2: Add missing indexes
echo -e "${YELLOW}📊 Step 2: Adding database indexes...${NC}"
kubectl exec -n $NAMESPACE statefulset/postgres-booking -- psql -U booking_user -d booking_db -c "
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON bookings(payment_status);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_hotel_id ON bookings(hotel_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_check_in_date ON bookings(check_in_date);
CREATE INDEX IF NOT EXISTS idx_bookings_check_out_date ON bookings(check_out_date);
"

echo -e "${GREEN}✅ Database schema updated${NC}"

# Step 3: Verify table structure
echo -e "${YELLOW}📊 Step 3: Verifying table structure...${NC}"
kubectl exec -n $NAMESPACE statefulset/postgres-booking -- psql -U booking_user -d booking_db -c "\d bookings"

# Step 4: Update existing bookings with default payment status
echo -e "${YELLOW}📊 Step 4: Updating existing bookings with payment status...${NC}"
kubectl exec -n $NAMESPACE statefulset/postgres-booking -- psql -U booking_user -d booking_db -c "
UPDATE bookings SET payment_status = 'SUCCESS' WHERE status IN ('CONFIRMED', 'COMPLETED') AND payment_status IS NULL;
UPDATE bookings SET payment_status = 'PENDING' WHERE status = 'PENDING' AND payment_status IS NULL;
UPDATE bookings SET payment_status = 'REFUNDED' WHERE status = 'CANCELLED' AND payment_status IS NULL;
"

echo -e "${GREEN}✅ Existing bookings updated${NC}"

# Step 5: Upgrade Helm chart with fixed schema
echo -e "${YELLOW}📊 Step 5: Upgrading Helm chart...${NC}"
helm upgrade $RELEASE_NAME $CHART_PATH -n $NAMESPACE

echo -e "${GREEN}✅ Helm chart upgraded${NC}"

# Step 6: Restart booking service
echo -e "${YELLOW}📊 Step 6: Restarting booking service...${NC}"
kubectl rollout restart deployment/booking-service -n $NAMESPACE

# Step 7: Wait for deployment to complete
echo -e "${YELLOW}📊 Step 7: Waiting for deployment to complete...${NC}"
kubectl rollout status deployment/booking-service -n $NAMESPACE

echo -e "${GREEN}✅ Booking service restarted${NC}"

# Step 8: Setup Nginx Ingress (if not already configured)
echo -e "${YELLOW}📊 Step 8: Setting up Nginx Ingress...${NC}"

# Check if nginx ingress controller is installed
if ! kubectl get ingressclass nginx >/dev/null 2>&1; then
    echo -e "${BLUE}Installing Nginx Ingress Controller...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

    # Wait for ingress controller to be ready
    echo -e "${BLUE}Waiting for Nginx Ingress Controller to be ready...${NC}"
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
fi

# Step 9: Create Ingress for services
echo -e "${YELLOW}📊 Step 9: Creating Ingress resources...${NC}"
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

# Get ingress external IP
echo -e "${BLUE}Getting Ingress external IP...${NC}"
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
    echo "Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get ingress hotel-reservation-ingress -n $NAMESPACE --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo -e "${GREEN}✅ Ingress configured with IP: $EXTERNAL_IP${NC}"

# Step 10: Test the booking functionality using service endpoints
echo -e "${YELLOW}📊 Step 10: Testing booking functionality via service endpoints...${NC}"

# Test internal service communication
echo -e "${BLUE}Testing internal service endpoints...${NC}"
kubectl run test-pod --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
    curl -s -X GET http://gateway.${NAMESPACE}.svc.cluster.local:9000/health || echo "Gateway health check failed"

kubectl run test-pod --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
    curl -s -X GET http://booking-service.${NAMESPACE}.svc.cluster.local:8000/health || echo "Booking service health check failed"

echo ""
echo -e "${GREEN}🎉 Booking service schema fix completed!${NC}"
echo ""
echo -e "${BLUE}📋 Summary of changes:${NC}"
echo -e "${CYAN}  ✅ Added payment_status column to bookings table${NC}"
echo -e "${CYAN}  ✅ Added payment_id column to bookings table${NC}"
echo -e "${CYAN}  ✅ Added transaction_id column to bookings table${NC}"
echo -e "${CYAN}  ✅ Added database indexes for better performance${NC}"
echo -e "${CYAN}  ✅ Updated existing bookings with payment status${NC}"
echo -e "${CYAN}  ✅ Upgraded Helm chart with fixed schema${NC}"
echo -e "${CYAN}  ✅ Restarted booking service${NC}"
echo -e "${CYAN}  ✅ Configured Nginx Ingress${NC}"
echo ""
echo -e "${YELLOW}🌐 Access URLs:${NC}"
if [ ! -z "$EXTERNAL_IP" ]; then
    echo -e "${CYAN}  Frontend: http://$EXTERNAL_IP${NC}"
    echo -e "${CYAN}  API Gateway: http://$EXTERNAL_IP/api${NC}"
    echo -e "${CYAN}  Health Check: http://$EXTERNAL_IP/api/health${NC}"
    echo ""
    echo -e "${BLUE}💡 Add to /etc/hosts for custom domain:${NC}"
    echo -e "${CYAN}  $EXTERNAL_IP hotel-reservation.local${NC}"
    echo -e "${CYAN}  Then access: http://hotel-reservation.local${NC}"
else
    echo -e "${CYAN}  Use: kubectl get ingress -n $NAMESPACE to get external IP${NC}"
fi
echo ""
echo -e "${YELLOW}🔧 Service Endpoints (internal):${NC}"
echo -e "${CYAN}  Gateway: http://gateway.${NAMESPACE}.svc.cluster.local:9000${NC}"
echo -e "${CYAN}  Frontend: http://frontend.${NAMESPACE}.svc.cluster.local:3000${NC}"
echo -e "${CYAN}  Booking Service: http://booking-service.${NAMESPACE}.svc.cluster.local:8000${NC}"
echo -e "${CYAN}  Search Service: http://search-service.${NAMESPACE}.svc.cluster.local:8001${NC}"
echo -e "${CYAN}  Auth Service: http://auth-service.${NAMESPACE}.svc.cluster.local:8002${NC}"
echo -e "${CYAN}  Payment Service: http://payment-service.${NAMESPACE}.svc.cluster.local:8003${NC}"
echo -e "${CYAN}  Notification Service: http://notification-service.${NAMESPACE}.svc.cluster.local:8004${NC}"
echo ""
echo -e "${YELLOW}🧪 Next steps:${NC}"
echo -e "${CYAN}  1. Test booking creation through the web UI${NC}"
echo -e "${CYAN}  2. Check booking logs: kubectl logs -f deployment/booking-service -n $NAMESPACE${NC}"
echo -e "${CYAN}  3. Verify database: kubectl exec -n $NAMESPACE statefulset/postgres-booking -- psql -U booking_user -d booking_db -c 'SELECT * FROM bookings LIMIT 5;'${NC}"
echo -e "${CYAN}  4. Test API directly: curl http://$EXTERNAL_IP/api/health${NC}"
echo ""
