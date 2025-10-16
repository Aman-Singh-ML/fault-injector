#!/bin/bash

# Deploy Hotel Reservation System with Integrated Nginx
# This script deploys the complete system with nginx as a reverse proxy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-"hotel-reservation"}
RELEASE_NAME=${RELEASE_NAME:-"hotel-reservation"}
CHART_PATH=${CHART_PATH:-"helm/hotel-reservation-system"}
TIMEOUT=${TIMEOUT:-"15m"}
BUILD_IMAGES=${BUILD_IMAGES:-"true"}
WAIT_FOR_READY=${WAIT_FOR_READY:-"true"}

# Print banner
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}🏨 HOTEL RESERVATION SYSTEM - NGINX DEPLOYMENT${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Step 1: Checking Prerequisites...${NC}"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed${NC}"
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}❌ Helm is not installed${NC}"
        exit 1
    fi
    
    # Check if docker is installed (for building images)
    if [[ "$BUILD_IMAGES" == "true" ]] && ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        exit 1
    fi
    
    # Check Kubernetes connection
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    # Check if nginx ingress controller is available
    if ! kubectl get ingressclass nginx &> /dev/null; then
        echo -e "${YELLOW}⚠️  Nginx Ingress Controller not found. Installing...${NC}"
        
        # Check if we're using minikube
        if command -v minikube &> /dev/null && minikube status &> /dev/null; then
            echo -e "${BLUE}📦 Enabling minikube ingress addon...${NC}"
            minikube addons enable ingress
        else
            echo -e "${BLUE}📦 Installing nginx ingress controller...${NC}"
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
            
            echo -e "${BLUE}⏳ Waiting for ingress controller to be ready...${NC}"
            kubectl wait --namespace ingress-nginx \
                --for=condition=ready pod \
                --selector=app.kubernetes.io/component=controller \
                --timeout=300s
        fi
    fi
    
    echo -e "${GREEN}✅ Prerequisites check completed${NC}"
    echo ""
}

# Function to build Docker images
build_images() {
    if [[ "$BUILD_IMAGES" == "true" ]]; then
        echo -e "${YELLOW}🔨 Step 2: Building Docker Images...${NC}"
        
        # Build all service images
        echo -e "${BLUE}Building Gateway image...${NC}"
        docker build -t amansingh2708/gateway:latest ./gateway
        
        echo -e "${BLUE}Building Frontend image...${NC}"
        docker build -t amansingh2708/frontend:latest ./frontend
        
        echo -e "${BLUE}Building Auth Service image...${NC}"
        docker build -t amansingh2708/auth-service:latest ./services/auth-service
        
        echo -e "${BLUE}Building Search Service image...${NC}"
        docker build -t amansingh2708/search-service:latest ./services/search-service
        
        echo -e "${BLUE}Building Booking Service image...${NC}"
        docker build -t amansingh2708/booking-service:latest ./services/booking-service
        
        echo -e "${BLUE}Building Payment Service image...${NC}"
        docker build -t amansingh2708/payment-service:latest ./services/payment-service
        
        echo -e "${BLUE}Building Notification Service image...${NC}"
        docker build -t amansingh2708/notification-service:latest ./services/notification-service
        
        # Load images to minikube if using minikube
        if command -v minikube &> /dev/null && minikube status &> /dev/null; then
            echo -e "${BLUE}📦 Loading images to minikube...${NC}"
            minikube image load amansingh2708/gateway:latest
            minikube image load amansingh2708/frontend:latest
            minikube image load amansingh2708/auth-service:latest
            minikube image load amansingh2708/search-service:latest
            minikube image load amansingh2708/booking-service:latest
            minikube image load amansingh2708/payment-service:latest
            minikube image load amansingh2708/notification-service:latest
        fi
        
        echo -e "${GREEN}✅ Docker images built successfully${NC}"
        echo ""
    else
        echo -e "${YELLOW}⏭️  Step 2: Skipping image build (BUILD_IMAGES=false)${NC}"
        echo ""
    fi
}

# Function to create namespace
create_namespace() {
    echo -e "${YELLOW}🏗️  Step 3: Creating Namespace...${NC}"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo -e "${BLUE}📦 Namespace '$NAMESPACE' already exists${NC}"
    else
        kubectl create namespace "$NAMESPACE"
        echo -e "${GREEN}✅ Namespace '$NAMESPACE' created${NC}"
    fi
    echo ""
}

# Function to deploy with Helm
deploy_helm() {
    echo -e "${YELLOW}🚀 Step 4: Deploying with Helm...${NC}"
    
    # Check if release exists
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        echo -e "${BLUE}📦 Upgrading existing Helm release...${NC}"
        helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
            --namespace "$NAMESPACE" \
            --set nginx.enabled=true \
            --set ingress.enabled=true \
            --set frontend.service.type=ClusterIP \
            --set gateway.service.type=ClusterIP \
            --wait \
            --timeout "$TIMEOUT"
        echo -e "${GREEN}✅ Helm release upgraded${NC}"
    else
        echo -e "${BLUE}📦 Installing new Helm release...${NC}"
        helm install "$RELEASE_NAME" "$CHART_PATH" \
            --namespace "$NAMESPACE" \
            --create-namespace \
            --set nginx.enabled=true \
            --set ingress.enabled=true \
            --set frontend.service.type=ClusterIP \
            --set gateway.service.type=ClusterIP \
            --wait \
            --timeout "$TIMEOUT"
        echo -e "${GREEN}✅ Helm release installed${NC}"
    fi
    echo ""
}

# Function to wait for deployment readiness
wait_for_ready() {
    if [[ "$WAIT_FOR_READY" == "true" ]]; then
        echo -e "${YELLOW}⏳ Step 5: Waiting for Deployment Readiness...${NC}"
        
        # Wait for all deployments to be ready
        echo -e "${BLUE}Waiting for deployments to be ready...${NC}"
        kubectl wait --for=condition=available --timeout=300s deployment --all -n "$NAMESPACE"
        
        # Wait for all pods to be ready
        echo -e "${BLUE}Waiting for pods to be ready...${NC}"
        kubectl wait --for=condition=ready --timeout=300s pod --all -n "$NAMESPACE"
        
        echo -e "${GREEN}✅ All deployments are ready${NC}"
        echo ""
    else
        echo -e "${YELLOW}⏭️  Step 5: Skipping readiness wait (WAIT_FOR_READY=false)${NC}"
        echo ""
    fi
}

# Function to configure local DNS
configure_dns() {
    echo -e "${YELLOW}🌐 Step 6: DNS Configuration...${NC}"
    
    # Check if entry already exists in /etc/hosts
    if grep -q "hotel-reservation.local" /etc/hosts 2>/dev/null; then
        echo -e "${BLUE}📝 DNS entry already exists in /etc/hosts${NC}"
    else
        echo -e "${YELLOW}⚠️  Please add the following entry to your /etc/hosts file:${NC}"
        echo -e "${CYAN}127.0.0.1 hotel-reservation.local${NC}"
        echo ""
        echo -e "${YELLOW}On Windows, edit: C:\\Windows\\System32\\drivers\\etc\\hosts${NC}"
        echo -e "${YELLOW}On Linux/Mac, edit: /etc/hosts${NC}"
    fi
    echo ""
}

# Function to display access information
display_access_info() {
    echo -e "${YELLOW}🌍 Step 7: Access Information${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Get ingress information
    INGRESS_IP=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -z "$INGRESS_IP" ]]; then
        # Try to get NodePort or use localhost for minikube
        if command -v minikube &> /dev/null && minikube status &> /dev/null; then
            INGRESS_IP="127.0.0.1"
        else
            INGRESS_IP="<EXTERNAL-IP>"
        fi
    fi
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}📱 Application Access:${NC}"
    echo -e "${CYAN}  Frontend: http://hotel-reservation.local${NC}"
    echo -e "${CYAN}  API Gateway: http://hotel-reservation.local/api${NC}"
    echo -e "${CYAN}  Health Check: http://hotel-reservation.local/api/health${NC}"
    echo ""
    
    echo -e "${CYAN}🔐 Login Credentials:${NC}"
    echo -e "${CYAN}  Customer: a@a.com / 123456${NC}"
    echo -e "${CYAN}  Admin: admin@hotel.com / admin123${NC}"
    echo ""
    
    echo -e "${CYAN}🛠️  Useful Commands:${NC}"
    echo -e "${CYAN}  View pods: kubectl get pods -n $NAMESPACE${NC}"
    echo -e "${CYAN}  View services: kubectl get svc -n $NAMESPACE${NC}"
    echo -e "${CYAN}  View ingress: kubectl get ingress -n $NAMESPACE${NC}"
    echo -e "${CYAN}  View logs: kubectl logs -f deployment/nginx -n $NAMESPACE${NC}"
    echo -e "${CYAN}  Uninstall: helm uninstall $RELEASE_NAME -n $NAMESPACE${NC}"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    build_images
    create_namespace
    deploy_helm
    wait_for_ready
    configure_dns
    display_access_info
    
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎊 Hotel Reservation System with Nginx deployed successfully!${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main "$@"
