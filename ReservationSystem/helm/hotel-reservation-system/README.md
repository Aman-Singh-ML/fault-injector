# Hotel Reservation System - Helm Chart

A comprehensive Helm chart for deploying the Hotel Reservation System, a microservices-based application demonstrating modern distributed system architecture.

## 🏗️ Architecture Overview

This Helm chart deploys a complete microservices ecosystem including:

### **Application Services**
- **Gateway** (Node.js/Express) - API Gateway and routing
- **Auth Service** (Java/Spring Boot) - Authentication and authorization
- **Search Service** (Go/Gin) - Hotel search and filtering
- **Booking Service** (Python/FastAPI) - Reservation management
- **Payment Service** (Go/Gin) - Payment processing
- **Notification Service** (Python/FastAPI) - Event-driven notifications

### **Infrastructure Components**
- **PostgreSQL** (3 isolated instances) - Database per service pattern
- **MongoDB** - Document storage for hotels and notifications
- **Redis** - Caching and session storage
- **Kafka** - Event streaming for booking events
- **RabbitMQ** - Message queuing for notifications
- **Zookeeper** - Kafka coordination

## 🚀 Quick Start

### Prerequisites
- Kubernetes 1.20+
- Helm 3.8+
- Docker (for building images)
- 8GB+ RAM available in cluster
- 20GB+ storage

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd ReservationSystem
   ```

2. **Build Docker images:**
   ```bash
   ./scripts/build-images.sh
   ```

3. **Deploy with Helm:**
   ```bash
   ./scripts/deploy-helm.sh
   ```

4. **Verify deployment:**
   ```bash
   ./scripts/test-deployment.sh
   ```

## 📋 Configuration

### Environment-Specific Deployments

The chart supports multiple environments through values files:

```bash
# Development (default)
helm install hotel-reservation helm/hotel-reservation-system

# Staging
helm install hotel-reservation helm/hotel-reservation-system \
  --set global.environment=staging \
  --set gateway.replicaCount=2

# Production
helm install hotel-reservation helm/hotel-reservation-system \
  --set global.environment=production \
  --set gateway.replicaCount=3 \
  --set hpa.enabled=true
```

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace | `hotel-reservation` |
| `global.environment` | Environment (dev/staging/prod) | `development` |
| `global.imageRegistry` | Docker registry | `""` (local) |
| `ingress.enabled` | Enable Ingress | `false` |
| `hpa.enabled` | Enable auto-scaling | `false` |
| `networkPolicy.enabled` | Enable network policies | `false` |
| `serviceMonitor.enabled` | Enable Prometheus monitoring | `false` |

## 🔧 Customization

### Custom Values File

Create a custom values file for your environment:

```yaml
# values-production.yaml
global:
  environment: production
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

hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

networkPolicy:
  enabled: true

serviceMonitor:
  enabled: true
```

Deploy with custom values:
```bash
helm install hotel-reservation helm/hotel-reservation-system \
  --values values-production.yaml
```

## 🛠️ Management Commands

### Deployment
```bash
# Install
./scripts/deploy-helm.sh --environment production

# Upgrade
./scripts/upgrade-helm.sh --values values-production.yaml

# Uninstall
./scripts/uninstall-helm.sh
```

### Monitoring
```bash
# Check status
helm status hotel-reservation -n hotel-reservation

# View pods
kubectl get pods -n hotel-reservation

# View logs
kubectl logs -f deployment/gateway -n hotel-reservation

# Port forward for local access
kubectl port-forward -n hotel-reservation service/gateway 9000:9000
```

### Testing
```bash
# Run comprehensive tests
./scripts/test-deployment.sh --verbose

# Test specific component
kubectl exec -n hotel-reservation deployment/gateway -- curl -s http://localhost:9000/health
```

## 🔐 Security

### Default Credentials
- **Admin User**: `admin@hotel.com` / `admin123`
- **Customer User**: `a@a.com` / `123456`
- **RabbitMQ**: `admin` / `admin123`
- **Database passwords**: Auto-generated (see values.yaml)

### Security Features
- Network policies for service isolation
- Security contexts with non-root users
- Resource limits and requests
- Health checks and probes
- Secret management for sensitive data

## 📊 Monitoring & Observability

### Prometheus Integration
Enable ServiceMonitor for Prometheus scraping:
```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 30s
```

### Health Endpoints
- Gateway: `http://gateway:9000/health`
- Auth Service: `http://auth-service:8080/actuator/health`
- Search Service: `http://search-service:8081/health`
- Booking Service: `http://booking-service:8000/health`
- Payment Service: `http://payment-service:8082/health`
- Notification Service: `http://notification-service:8083/health`

### Metrics Endpoints
- Gateway: `http://gateway:9000/metrics`
- Auth Service: `http://auth-service:8080/actuator/prometheus`
- Other services: `http://service:port/metrics`

## 🔄 Scaling

### Horizontal Pod Autoscaling
```yaml
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### Manual Scaling
```bash
# Scale specific service
kubectl scale deployment gateway -n hotel-reservation --replicas=5

# Scale all services
helm upgrade hotel-reservation helm/hotel-reservation-system \
  --set gateway.replicaCount=3 \
  --set authService.replicaCount=2
```

## 🗄️ Data Persistence

### Persistent Volumes
- PostgreSQL instances: 10Gi each
- MongoDB: 20Gi
- Redis: 5Gi
- Kafka: 10Gi
- RabbitMQ: 5Gi

### Backup Considerations
- Database backups should be configured separately
- PVCs are retained by default when uninstalling
- Use `--keep-pvc` flag with uninstall script to preserve data

## 🌐 Networking

### Service Mesh Integration
The chart is compatible with service mesh solutions like Istio:
```yaml
# Enable service mesh annotations
gateway:
  podAnnotations:
    sidecar.istio.io/inject: "true"
```

### Ingress Configuration
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    - secretName: hotel-reservation-tls
      hosts:
        - hotel.yourdomain.com
```

## 🐛 Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**
   ```bash
   kubectl describe pod <pod-name> -n hotel-reservation
   # Check resource constraints and node capacity
   ```

2. **Database connection failures**
   ```bash
   kubectl logs deployment/auth-service -n hotel-reservation
   # Check init containers and database readiness
   ```

3. **Service discovery issues**
   ```bash
   kubectl get endpoints -n hotel-reservation
   # Verify service endpoints are populated
   ```

### Debug Commands
```bash
# Check all resources
kubectl get all -n hotel-reservation

# View events
kubectl get events -n hotel-reservation --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n hotel-reservation

# Describe problematic resources
kubectl describe deployment <deployment-name> -n hotel-reservation
```

## 📚 Additional Resources

- [Values Reference](VALUES_REFERENCE.md) - Complete values.yaml documentation
- [Deployment Guide](../docs/HELM_DEPLOYMENT_GUIDE.md) - Detailed deployment instructions
- [Architecture Documentation](../docs/architecture.md) - System architecture details
- [API Documentation](../docs/api/) - Service API references

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./scripts/test-deployment.sh`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the logs and events

---

**Version**: 2.0.0  
**Kubernetes**: 1.20+  
**Helm**: 3.8+
