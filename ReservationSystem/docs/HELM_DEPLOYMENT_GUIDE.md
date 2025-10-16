# Hotel Reservation System - Helm Deployment Guide

This comprehensive guide covers deploying the Hotel Reservation System using Helm charts in various environments.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Deployment Process](#deployment-process)
4. [Configuration Management](#configuration-management)
5. [Monitoring & Maintenance](#monitoring--maintenance)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

## 🔧 Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Kubernetes | 1.20+ | 1.25+ |
| Helm | 3.8+ | 3.12+ |
| CPU | 4 cores | 8+ cores |
| Memory | 8GB | 16GB+ |
| Storage | 50GB | 100GB+ |
| Network | 1Gbps | 10Gbps+ |

### Required Tools

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# Verify installations
kubectl version --client
helm version
docker --version
```

### Kubernetes Cluster Setup

#### Local Development (minikube)
```bash
# Install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube && sudo mv minikube /usr/local/bin/

# Start cluster with sufficient resources
minikube start --cpus=4 --memory=8192 --disk-size=50g
minikube addons enable ingress
```

#### Production (EKS/GKE/AKS)
```bash
# AWS EKS
eksctl create cluster --name hotel-reservation --region us-west-2 --nodes 3 --node-type m5.large

# Google GKE
gcloud container clusters create hotel-reservation --num-nodes=3 --machine-type=n1-standard-4

# Azure AKS
az aks create --resource-group myResourceGroup --name hotel-reservation --node-count 3 --node-vm-size Standard_D4s_v3
```

## 🌍 Environment Setup

### Development Environment

```bash
# Clone repository
git clone <repository-url>
cd ReservationSystem

# Set environment variables
export ENVIRONMENT=development
export NAMESPACE=hotel-reservation-dev
export RELEASE_NAME=hotel-reservation-dev

# Create namespace
kubectl create namespace $NAMESPACE
```

### Staging Environment

```bash
# Set environment variables
export ENVIRONMENT=staging
export NAMESPACE=hotel-reservation-staging
export RELEASE_NAME=hotel-reservation-staging

# Create staging values file
cat > values-staging.yaml << EOF
global:
  environment: staging
  namespace: hotel-reservation-staging

gateway:
  replicaCount: 2
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

authService:
  replicaCount: 2

searchService:
  replicaCount: 2

bookingService:
  replicaCount: 2

paymentService:
  replicaCount: 2

notificationService:
  replicaCount: 2

hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 5

networkPolicy:
  enabled: true
EOF
```

### Production Environment

```bash
# Set environment variables
export ENVIRONMENT=production
export NAMESPACE=hotel-reservation
export RELEASE_NAME=hotel-reservation

# Create production values file
cat > values-production.yaml << EOF
global:
  environment: production
  namespace: hotel-reservation
  imageRegistry: "your-registry.com"

gateway:
  replicaCount: 3
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

authService:
  replicaCount: 3
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

# Enable all production features
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: hotel.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
          service: gateway
          port: 9000
  tls:
    - secretName: hotel-reservation-tls
      hosts:
        - hotel.yourdomain.com

hpa:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

networkPolicy:
  enabled: true

serviceMonitor:
  enabled: true
  namespace: monitoring

# Production database settings
postgresAuth:
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  persistence:
    size: 20Gi

postgresBooking:
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  persistence:
    size: 20Gi

postgresPayment:
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  persistence:
    size: 20Gi

mongodb:
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
  persistence:
    size: 50Gi

redis:
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  persistence:
    size: 10Gi

kafka:
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
  persistence:
    size: 20Gi

rabbitmq:
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  persistence:
    size: 10Gi
EOF
```

## 🚀 Deployment Process

### Step 1: Build Docker Images

```bash
# Build all images
./scripts/build-images.sh --tag latest

# For production with registry
./scripts/build-images.sh --registry your-registry.com --tag v1.0.0 --push
```

### Step 2: Deploy Infrastructure First (Optional)

For large deployments, you might want to deploy infrastructure components first:

```bash
# Deploy only infrastructure
helm install hotel-reservation-infra helm/hotel-reservation-system \
  --namespace $NAMESPACE \
  --create-namespace \
  --set gateway.enabled=false \
  --set authService.enabled=false \
  --set searchService.enabled=false \
  --set bookingService.enabled=false \
  --set paymentService.enabled=false \
  --set notificationService.enabled=false \
  --wait
```

### Step 3: Deploy Application Services

```bash
# Development deployment
./scripts/deploy-helm.sh --environment development

# Staging deployment
./scripts/deploy-helm.sh \
  --environment staging \
  --values-file values-staging.yaml \
  --namespace hotel-reservation-staging

# Production deployment
./scripts/deploy-helm.sh \
  --environment production \
  --values-file values-production.yaml \
  --namespace hotel-reservation \
  --timeout 20m
```

### Step 4: Verify Deployment

```bash
# Run comprehensive tests
./scripts/test-deployment.sh --namespace $NAMESPACE --verbose

# Check deployment status
helm status $RELEASE_NAME -n $NAMESPACE

# Verify all pods are running
kubectl get pods -n $NAMESPACE

# Check services
kubectl get services -n $NAMESPACE
```

## ⚙️ Configuration Management

### Environment-Specific Configurations

#### Database Configurations
```yaml
# Development - smaller resources
postgresAuth:
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
  persistence:
    size: 5Gi

# Production - larger resources
postgresAuth:
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
  persistence:
    size: 20Gi
    storageClass: "fast-ssd"
```

#### Service Configurations
```yaml
# Development - single replica
gateway:
  replicaCount: 1
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"

# Production - multiple replicas with HPA
gateway:
  replicaCount: 3
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
  hpa:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
```

### Secret Management

```bash
# Create secrets for sensitive data
kubectl create secret generic hotel-reservation-secrets \
  --from-literal=jwt-secret="your-jwt-secret" \
  --from-literal=db-password="secure-password" \
  --namespace $NAMESPACE

# Use external secret management (recommended for production)
# Example with AWS Secrets Manager
kubectl apply -f - << EOF
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: $NAMESPACE
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
EOF
```

### ConfigMap Management

```bash
# Create custom configuration
kubectl create configmap hotel-reservation-config \
  --from-file=config.yaml \
  --namespace $NAMESPACE

# Update configuration
kubectl patch configmap hotel-reservation-config \
  --patch '{"data":{"config.yaml":"new-config-content"}}' \
  --namespace $NAMESPACE
```

## 📊 Monitoring & Maintenance

### Health Monitoring

```bash
# Check pod health
kubectl get pods -n $NAMESPACE -o wide

# Check resource usage
kubectl top pods -n $NAMESPACE
kubectl top nodes

# View logs
kubectl logs -f deployment/gateway -n $NAMESPACE
kubectl logs -f statefulset/postgres-auth -n $NAMESPACE
```

### Prometheus Integration

```yaml
# Enable ServiceMonitor
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 30s
  scrapeTimeout: 10s
  labels:
    release: prometheus
```

### Grafana Dashboards

```bash
# Import pre-built dashboards
kubectl apply -f monitoring/grafana-dashboards/
```

### Backup Procedures

```bash
# Database backups
kubectl exec -n $NAMESPACE statefulset/postgres-auth -- pg_dump -U authuser authdb > auth-backup.sql
kubectl exec -n $NAMESPACE statefulset/mongodb -- mongodump --out /tmp/backup

# PVC snapshots (if supported)
kubectl apply -f - << EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-auth-snapshot
  namespace: $NAMESPACE
spec:
  source:
    persistentVolumeClaimName: postgres-auth-pvc
EOF
```

## 🔄 Upgrade Procedures

### Rolling Updates

```bash
# Update image tags
helm upgrade $RELEASE_NAME helm/hotel-reservation-system \
  --namespace $NAMESPACE \
  --set gateway.image.tag=v1.1.0 \
  --set authService.image.tag=v1.1.0

# Update with new values file
./scripts/upgrade-helm.sh --values-file values-production-v2.yaml
```

### Blue-Green Deployments

```bash
# Deploy new version to separate namespace
export NEW_NAMESPACE=hotel-reservation-v2
./scripts/deploy-helm.sh --namespace $NEW_NAMESPACE

# Switch traffic (update ingress or load balancer)
kubectl patch ingress hotel-reservation-ingress \
  --patch '{"spec":{"rules":[{"host":"hotel.yourdomain.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"gateway-v2","port":{"number":9000}}}}]}}]}}'

# Cleanup old version after verification
./scripts/uninstall-helm.sh --namespace hotel-reservation-v1
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. Pods Stuck in Pending State
```bash
# Check node resources
kubectl describe nodes

# Check PVC status
kubectl get pvc -n $NAMESPACE

# Check resource quotas
kubectl describe resourcequota -n $NAMESPACE
```

#### 2. Database Connection Issues
```bash
# Check database pod logs
kubectl logs statefulset/postgres-auth -n $NAMESPACE

# Test connectivity
kubectl exec -n $NAMESPACE deployment/auth-service -- nc -zv postgres-auth 5432

# Check init containers
kubectl describe pod <pod-name> -n $NAMESPACE
```

#### 3. Service Discovery Problems
```bash
# Check DNS resolution
kubectl exec -n $NAMESPACE deployment/gateway -- nslookup auth-service

# Check endpoints
kubectl get endpoints -n $NAMESPACE

# Check service configuration
kubectl describe service auth-service -n $NAMESPACE
```

#### 4. Performance Issues
```bash
# Check resource usage
kubectl top pods -n $NAMESPACE
kubectl top nodes

# Check HPA status
kubectl get hpa -n $NAMESPACE

# Analyze slow queries (PostgreSQL)
kubectl exec -n $NAMESPACE statefulset/postgres-auth -- psql -U authuser -d authdb -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

### Debug Commands

```bash
# Get all resources
kubectl get all -n $NAMESPACE

# Describe problematic resources
kubectl describe deployment gateway -n $NAMESPACE
kubectl describe pod <pod-name> -n $NAMESPACE

# Check events
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'

# Port forward for debugging
kubectl port-forward -n $NAMESPACE service/gateway 9000:9000

# Execute commands in pods
kubectl exec -it -n $NAMESPACE deployment/gateway -- /bin/bash
```

## 🏆 Best Practices

### Security Best Practices

1. **Use Network Policies**
   ```yaml
   networkPolicy:
     enabled: true
   ```

2. **Enable Security Contexts**
   ```yaml
   global:
     securityContext:
       runAsNonRoot: true
       runAsUser: 1000
       fsGroup: 2000
   ```

3. **Use Secrets for Sensitive Data**
   ```yaml
   authService:
     env:
       JWT_SECRET:
         valueFrom:
           secretKeyRef:
             name: hotel-reservation-secrets
             key: jwt-secret
   ```

### Performance Best Practices

1. **Set Resource Limits**
   ```yaml
   gateway:
     resources:
       requests:
         memory: "256Mi"
         cpu: "250m"
       limits:
         memory: "512Mi"
         cpu: "500m"
   ```

2. **Enable HPA**
   ```yaml
   hpa:
     enabled: true
     minReplicas: 2
     maxReplicas: 10
     targetCPUUtilizationPercentage: 70
   ```

3. **Use Persistent Volumes**
   ```yaml
   postgresAuth:
     persistence:
       enabled: true
       size: 20Gi
       storageClass: "fast-ssd"
   ```

### Operational Best Practices

1. **Use Health Checks**
   ```yaml
   gateway:
     livenessProbe:
       httpGet:
         path: /health
         port: 9000
     readinessProbe:
       httpGet:
         path: /health
         port: 9000
   ```

2. **Implement Monitoring**
   ```yaml
   serviceMonitor:
     enabled: true
   ```

3. **Regular Backups**
   ```bash
   # Schedule regular database backups
   kubectl create cronjob postgres-backup \
     --image=postgres:16-alpine \
     --schedule="0 2 * * *" \
     -- pg_dump -h postgres-auth -U authuser authdb
   ```

4. **Version Control Configuration**
   ```bash
   # Store values files in version control
   git add values-production.yaml
   git commit -m "Update production configuration"
   ```

---

This guide provides comprehensive instructions for deploying and managing the Hotel Reservation System using Helm. For additional support, refer to the troubleshooting section or create an issue in the repository.

## 📚 Additional Resources

- [Helm Chart README](../helm/hotel-reservation-system/README.md)
- [Values Reference](VALUES_REFERENCE.md)
- [Architecture Documentation](architecture.md)
- [API Documentation](api/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with `./scripts/test-deployment.sh`
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
