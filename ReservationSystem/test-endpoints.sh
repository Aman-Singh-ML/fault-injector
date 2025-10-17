#!/bin/bash

echo "🔍 Hotel Reservation System - Endpoint Testing"
echo "=============================================="

# Get the external IP
echo "📡 Getting LoadBalancer IP..."
EXTERNAL_IP=$(kubectl get svc -n hotel-reservation nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
    echo "❌ LoadBalancer IP not available yet. Checking for pending..."
    kubectl get svc -n hotel-reservation nginx
    exit 1
fi

echo "✅ External IP: $EXTERNAL_IP"
echo ""

# Function to test endpoint
test_endpoint() {
    local name="$1"
    local path="$2"
    local expected_status="$3"
    local url="http://$EXTERNAL_IP$path"
    
    echo -n "🧪 Testing $name ($path)... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "$url")
    
    if [ "$response" = "$expected_status" ]; then
        echo "✅ $response"
    else
        echo "❌ $response (expected $expected_status)"
        # Get more details for debugging
        echo "   URL: $url"
        curl -s -I "$url" | head -5 | sed 's/^/   /'
    fi
}

# Function to test service connectivity from nginx pod
test_internal_connectivity() {
    echo "🔗 Testing Internal Service Connectivity"
    echo "----------------------------------------"
    
    # Get nginx pod name
    NGINX_POD=$(kubectl get pods -n hotel-reservation -l app.kubernetes.io/name=nginx -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$NGINX_POD" ]; then
        echo "❌ Nginx pod not found"
        return
    fi
    
    echo "📦 Using Nginx pod: $NGINX_POD"
    
    # Test internal service resolution
    services=("grafana:3000" "prometheus:9090" "jaeger-query:16686" "loki:3100" "gateway:8080" "frontend:3000")
    
    for service in "${services[@]}"; do
        service_name=$(echo $service | cut -d: -f1)
        service_port=$(echo $service | cut -d: -f2)
        
        echo -n "   🔍 $service_name:$service_port... "
        
        # Test DNS resolution
        if kubectl exec -n hotel-reservation "$NGINX_POD" -- nslookup "$service_name" >/dev/null 2>&1; then
            # Test connectivity
            if kubectl exec -n hotel-reservation "$NGINX_POD" -- wget -qO- --timeout=5 "http://$service" >/dev/null 2>&1; then
                echo "✅ OK"
            else
                echo "❌ Connection failed"
            fi
        else
            echo "❌ DNS resolution failed"
        fi
    done
    echo ""
}

# Test all endpoints
echo "🌐 Testing External Endpoints"
echo "-----------------------------"

# Health check
test_endpoint "Health Check" "/health" "200"

# Application endpoints
test_endpoint "API Gateway" "/api/" "200"
test_endpoint "Frontend App (Default)" "/" "200"

# Observability endpoints
test_endpoint "Grafana" "/grafana/" "200"
test_endpoint "Prometheus" "/prometheus/" "200"
test_endpoint "Jaeger" "/jaeger/" "200"
test_endpoint "Loki API" "/loki/ready" "200"

echo ""

# Test internal connectivity
test_internal_connectivity

# Check pod status
echo "📊 Pod Status"
echo "-------------"
kubectl get pods -n hotel-reservation -o wide

echo ""

# Check service status
echo "🔧 Service Status"
echo "----------------"
kubectl get svc -n hotel-reservation

echo ""

# Check nginx configuration
echo "⚙️  Nginx Configuration Check"
echo "-----------------------------"
NGINX_POD=$(kubectl get pods -n hotel-reservation -l app.kubernetes.io/name=nginx -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$NGINX_POD" ]; then
    echo "📋 Nginx upstreams:"
    kubectl exec -n hotel-reservation "$NGINX_POD" -- nginx -T 2>/dev/null | grep -A 2 "upstream.*backend" | head -20
    echo ""
    echo "📋 Nginx locations:"
    kubectl exec -n hotel-reservation "$NGINX_POD" -- nginx -T 2>/dev/null | grep "location" | head -10
fi

echo ""
echo "🎯 Summary"
echo "----------"
echo "Frontend: http://$EXTERNAL_IP/ (Main URL)"
echo "Grafana:  http://$EXTERNAL_IP/grafana/ (admin/admin123)"
echo "API:      http://$EXTERNAL_IP/api/"
echo "API:      http://$EXTERNAL_IP/api/"
echo "Prometheus: http://$EXTERNAL_IP/prometheus/"
echo "Jaeger:   http://$EXTERNAL_IP/jaeger/"
