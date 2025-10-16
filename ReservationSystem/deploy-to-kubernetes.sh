#!/bin/bash

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DEPLOYING HOTEL RESERVATION SYSTEM TO KUBERNETES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Kubernetes is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster is not accessible. Please start your Kubernetes cluster (Docker Desktop, Minikube, etc.)"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Step 1: Build Docker Images
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 1: Building Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build Gateway
echo "1️⃣  Building Gateway..."
docker build -t gateway:latest ./gateway
echo "   ✅ Gateway image built"

# Build Search Service
echo ""
echo "2️⃣  Building Search Service..."
docker build -t search-service:latest ./services/search-service
echo "   ✅ Search Service image built"

# Build Booking Service
echo ""
echo "3️⃣  Building Booking Service..."
docker build -t booking-service:latest ./services/booking-service
echo "   ✅ Booking Service image built"

# Build Payment Service
echo ""
echo "4️⃣  Building Payment Service..."
docker build -t payment-service:latest ./services/payment-service
echo "   ✅ Payment Service image built"

# Build Notification Service
echo ""
echo "5️⃣  Building Notification Service..."
docker build -t notification-service:latest ./services/notification-service
echo "   ✅ Notification Service image built"

# Build Auth Service (if Dockerfile exists)
if [ -f "./services/auth-service/Dockerfile" ]; then
    echo ""
    echo "6️⃣  Building Auth Service..."
    docker build -t auth-service:latest ./services/auth-service
    echo "   ✅ Auth Service image built"
else
    echo ""
    echo "⚠️  Auth Service Dockerfile not found, skipping..."
fi

echo ""
echo "✅ All Docker images built successfully"
echo ""

# Step 2: Create Namespace
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 STEP 2: Creating Kubernetes Namespace"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

kubectl create namespace hotel-reservation --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace 'hotel-reservation' created/verified"
echo ""

# Step 3: Deploy with Helm
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚓ STEP 3: Deploying with Helm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if release exists
if helm list -n hotel-reservation | grep -q hotel-reservation; then
    echo "📦 Upgrading existing Helm release..."
    helm upgrade hotel-reservation ./helm/hotel-reservation \
        --namespace hotel-reservation \
        --wait \
        --timeout 10m
    echo "✅ Helm release upgraded"
else
    echo "📦 Installing new Helm release..."
    helm install hotel-reservation ./helm/hotel-reservation \
        --namespace hotel-reservation \
        --create-namespace \
        --wait \
        --timeout 10m
    echo "✅ Helm release installed"
fi

echo ""

# Step 4: Wait for Pods to be Ready
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ STEP 4: Waiting for Pods to be Ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Waiting for all pods to be ready (this may take a few minutes)..."
kubectl wait --for=condition=ready pod --all -n hotel-reservation --timeout=600s || true

echo ""
echo "✅ Deployment complete"
echo ""

# Step 5: Display Status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 STEP 5: Deployment Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔍 Pods Status:"
kubectl get pods -n hotel-reservation
echo ""

echo "🌐 Services:"
kubectl get svc -n hotel-reservation
echo ""

echo "💾 Persistent Volume Claims:"
kubectl get pvc -n hotel-reservation
echo ""

# Step 6: Get Access Information
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌍 STEP 6: Access Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get NodePort for Gateway
GATEWAY_PORT=$(kubectl get svc gateway -n hotel-reservation -o jsonpath='{.spec.ports[0].nodePort}')
echo "📱 API Gateway Access:"
echo "   URL: http://localhost:$GATEWAY_PORT"
echo "   Health Check: http://localhost:$GATEWAY_PORT/health"
echo ""

echo "🔐 Login Credentials:"
echo "   Customer: a@a.com / 123456"
echo "   Admin: admin@hotel.com / admin123"
echo ""

echo "📝 Useful Commands:"
echo "   View logs: kubectl logs -f <pod-name> -n hotel-reservation"
echo "   Port forward: kubectl port-forward svc/gateway 9000:9000 -n hotel-reservation"
echo "   Delete deployment: helm uninstall hotel-reservation -n hotel-reservation"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  Note: If pods are not ready, check logs with:"
echo "   kubectl logs -n hotel-reservation <pod-name>"
echo ""
echo "🧪 To test the deployment, run:"
echo "   ./test-kubernetes-deployment.sh"
echo ""

