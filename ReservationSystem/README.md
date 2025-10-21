# Hotel Reservation System - Deployment Guide

A cloud-native, polyglot microservices-based hotel reservation system with comprehensive observability stack.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Building Docker Images](#building-docker-images)
- [Deploying to Kubernetes](#deploying-to-kubernetes)
- [Accessing Services](#accessing-services)
- [Observability Stack](#observability-stack)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

### Microservices (Polyglot Architecture)

| Service | Language | Framework | Port | Database |
|---------|----------|-----------|------|----------|
| **API Gateway** | Node.js | Express | 9000 | - |
| **Auth Service** | Java 17 | Spring Boot 3.2 | 8080 | PostgreSQL |
| **Search Service** | Go 1.21 | Gin | 8081 | MongoDB |
| **Booking Service** | Python 3.11 | FastAPI | 8000 | PostgreSQL |
| **Payment Service** | Go 1.21 | Gin | 8082 | PostgreSQL |
| **Notification Service** | Python 3.11 | FastAPI | 8083 | - |
| **Inventory Service** | Java 17 | Spring Boot 3.2 | 8085 | PostgreSQL |
| **Pricing Service** | Java 17 | Spring Boot 3.2 | 8087 | PostgreSQL |

### Infrastructure Components

- **Message Brokers**: Kafka (Bitnami), RabbitMQ
- **Databases**: PostgreSQL, MongoDB, Redis
- **Observability**: Prometheus, Loki, Grafana, Jaeger
- **Ingress**: Nginx Ingress Controller

---

## 📦 Prerequisites

### Ubuntu VM Requirements

#### 1. System Packages

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    jq \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common
```

#### 2. Docker Installation

```bash
# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker buildx version
```

#### 3. Kubectl Installation

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

#### 4. Helm Installation

```bash
# Download and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

#### 5. Kubernetes Cluster

You need access to a Kubernetes cluster. Options:

**Option A: Azure Kubernetes Service (AKS)**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Create AKS cluster (example)
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

**Option B: Minikube (Local Development)**
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable ingress addon
minikube addons enable ingress
```

---

## 🔨 Building Docker Images

### Prerequisites for Building

```bash
# Ensure Docker Buildx is available
docker buildx version

# Create and use a new builder instance (supports multi-platform builds)
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap
```

### Build All Services

#### Option 1: Build and Push to Docker Hub

```bash
# Set your Docker Hub username
export DOCKER_USERNAME="amansingh2708"

# Login to Docker Hub
docker login

# Build and push all services
cd ReservationSystem

# API Gateway (Node.js)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-gateway:latest \
  -t ${DOCKER_USERNAME}/hotel-gateway:v1.0.0 \
  --push \
  ./gateway

# Auth Service (Java)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-auth-service:latest \
  -t ${DOCKER_USERNAME}/hotel-auth-service:v1.0.0 \
  --push \
  ./services/auth-service

# Search Service (Go)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-search-service:latest \
  -t ${DOCKER_USERNAME}/hotel-search-service:v1.0.0 \
  --push \
  ./services/search-service

# Booking Service (Python)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-booking-service:latest \
  -t ${DOCKER_USERNAME}/hotel-booking-service:v1.0.0 \
  --push \
  ./services/booking-service

# Payment Service (Go)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-payment-service:latest \
  -t ${DOCKER_USERNAME}/hotel-payment-service:v1.0.0 \
  --push \
  ./services/payment-service

# Notification Service (Python)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-notification-service:latest \
  -t ${DOCKER_USERNAME}/hotel-notification-service:v1.0.0 \
  --push \
  ./services/notification-service

# Inventory Service (Java)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-inventory-service:latest \
  -t ${DOCKER_USERNAME}/hotel-inventory-service:v1.0.0 \
  --push \
  ./services/inventory-service

# Pricing Service (Java)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${DOCKER_USERNAME}/hotel-pricing-service:latest \
  -t ${DOCKER_USERNAME}/hotel-pricing-service:v1.0.0 \
  --push \
  ./services/pricing-service
```

## 🚀 Deploying to Kubernetes

### Step 1: Create Namespace

```bash
kubectl create namespace hotel-reservation
```

### Step 2: Install Nginx Ingress Controller

```bash
# Add Nginx Ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install Nginx Ingress
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### Step 3: Configure Helm Values

Edit `helm/hotel-reservation-system/values.yaml`:

```yaml
global:
  namespace: hotel-reservation
  imageRegistry: docker.io
  imageRepository: amansingh2708  # Change to your Docker Hub username
  imageTag: latest
  imagePullPolicy: Always
```

### Step 4: Deploy the Application

```bash
cd ReservationSystem

# Install/Upgrade the Helm chart
helm upgrade --install hotel-reservation \
  ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --create-namespace \
  --timeout 10m \
  --wait

# Watch pods starting up
kubectl get pods -n hotel-reservation -w
```

## 🌐 Accessing Services

### Get Nginx Ingress IP

```bash
# Get LoadBalancer IP
export NGINX_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Nginx Ingress IP: $NGINX_IP"
```

### Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **API Gateway** | `http://$NGINX_IP/api` | - |


## 🧹 Cleanup

```bash
# Delete the application
helm uninstall hotel-reservation -n hotel-reservation

# Delete namespace
kubectl delete namespace hotel-reservation

# Delete ingress controller
helm uninstall nginx-ingress -n ingress-nginx
kubectl delete namespace ingress-nginx
```

---
