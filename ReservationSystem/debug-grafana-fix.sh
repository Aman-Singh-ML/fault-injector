#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="hotel-reservation"

echo -e "${BLUE}🔍 Grafana Debugging and Fix Script${NC}"
echo "=================================================="

# Step 1: Check Grafana Pod Status
echo -e "\n${YELLOW}📋 Step 1: Checking Grafana Pod Status${NC}"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana

GRAFANA_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$GRAFANA_POD" ]; then
    echo -e "${RED}❌ No Grafana pod found${NC}"
    exit 1
fi

echo -e "Grafana Pod: $GRAFANA_POD"

# Step 2: Check Pod Status
echo -e "\n${YELLOW}📋 Step 2: Checking Pod Details${NC}"
kubectl describe pod $GRAFANA_POD -n $NAMESPACE | grep -A 5 -B 5 "Status\|Ready\|Restart"

# Step 3: Check Service Configuration
echo -e "\n${YELLOW}🌐 Step 3: Checking Service Configuration${NC}"
kubectl get svc grafana -n $NAMESPACE
kubectl describe svc grafana -n $NAMESPACE | grep -A 10 "Type\|Port\|Endpoints"

# Step 4: Check Grafana Logs
echo -e "\n${YELLOW}📝 Step 4: Checking Grafana Logs (last 20 lines)${NC}"
kubectl logs $GRAFANA_POD -n $NAMESPACE --tail=20

# Step 5: Test Health Endpoint
echo -e "\n${YELLOW}🏥 Step 5: Testing Health Endpoint${NC}"
kubectl exec $GRAFANA_POD -n $NAMESPACE -- curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null
HEALTH_CODE=$?
if [ $HEALTH_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Health endpoint accessible${NC}"
else
    echo -e "${RED}❌ Health endpoint not accessible${NC}"
fi

# Step 6: Check Nginx Configuration
echo -e "\n${YELLOW}🌐 Step 6: Checking Nginx Configuration${NC}"
NGINX_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$NGINX_POD" ]; then
    echo "Testing nginx to grafana connectivity..."
    kubectl exec $NGINX_POD -n $NAMESPACE -- curl -s -o /dev/null -w "%{http_code}" http://grafana:3000/api/health 2>/dev/null
    NGINX_TEST=$?
    if [ $NGINX_TEST -eq 0 ]; then
        echo -e "${GREEN}✅ Nginx can reach Grafana${NC}"
    else
        echo -e "${RED}❌ Nginx cannot reach Grafana${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Nginx pod not found${NC}"
fi

# Step 7: Get Access URLs
echo -e "\n${YELLOW}🔗 Step 7: Access URLs${NC}"
NGINX_IP=$(kubectl get svc nginx -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -n "$NGINX_IP" ] && [ "$NGINX_IP" != "null" ]; then
    echo -e "${GREEN}Grafana via Nginx: http://$NGINX_IP/grafana/${NC}"
else
    echo -e "${YELLOW}Nginx LoadBalancer IP not available${NC}"
    echo -e "${BLUE}Use port-forward: kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE${NC}"
    echo -e "${BLUE}Then access: http://localhost:3000${NC}"
fi

# Step 8: Configuration Recommendations
echo -e "\n${YELLOW}💡 Step 8: Configuration Recommendations${NC}"
SERVICE_TYPE=$(kubectl get svc grafana -n $NAMESPACE -o jsonpath='{.spec.type}' 2>/dev/null)
echo "Current service type: $SERVICE_TYPE"

if [ "$SERVICE_TYPE" = "ClusterIP" ]; then
    echo -e "${GREEN}✅ Correct: Using ClusterIP for internal access${NC}"
    echo -e "${BLUE}💡 Access via nginx proxy: /grafana/${NC}"
elif [ "$SERVICE_TYPE" = "NodePort" ]; then
    NODE_PORT=$(kubectl get svc grafana -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    echo -e "${YELLOW}⚠️ Using NodePort: $NODE_PORT${NC}"
    echo -e "${BLUE}💡 Access via: http://<NODE_IP>:$NODE_PORT${NC}"
elif [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
    LB_IP=$(kubectl get svc grafana -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    echo -e "${YELLOW}⚠️ Using LoadBalancer: $LB_IP${NC}"
    echo -e "${BLUE}💡 Access via: http://$LB_IP:3000${NC}"
fi

echo -e "\n${GREEN}🎯 Default Credentials: admin / admin123${NC}"
echo -e "${BLUE}📚 For more help, check the logs above or run:${NC}"
echo -e "${BLUE}   kubectl logs -f $GRAFANA_POD -n $NAMESPACE${NC}"
