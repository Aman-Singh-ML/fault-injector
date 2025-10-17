# 🌐 Nginx Ingress Controller Setup Guide

This guide explains how to deploy the Hotel Reservation System with integrated Nginx Ingress Controller for dynamic routing and observability access.

## 🏗️ Architecture Overview

```
Internet → LoadBalancer → Nginx Ingress Controller → Services
                                ↓
                    ┌─────────────────────────────┐
                    │     Ingress Routes          │
                    ├─────────────────────────────┤
                    │ /           → Frontend      │
                    │ /api/*      → Gateway       │
                    │ /grafana/*  → Grafana       │
                    │ /prometheus/* → Prometheus  │
                    │ /jaeger/*   → Jaeger        │
                    │ /loki/*     → Loki          │
                    └─────────────────────────────┘
```

## 🚀 Quick Deployment

### **Option 1: Automated Deployment (Recommended)**

```bash
# Make the script executable
chmod +x scripts/deploy-with-ingress-controller.sh

# Deploy everything
./scripts/deploy-with-ingress-controller.sh
```

### **Option 2: Manual Deployment**

```bash
# 1. Add Helm repositories
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 2. Update dependencies
cd helm/hotel-reservation-system
helm dependency update
cd ../..

# 3. Deploy with ingress controller
helm upgrade --install hotel-reservation ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --create-namespace \
  --values helm/hotel-reservation-system/values-aks.yaml \
  --wait \
  --timeout 15m
```

## 🔧 Configuration Options

### **Enable/Disable Ingress Controller**

In your `values-aks.yaml`:

```yaml
# Install ingress controller as part of this chart
ingressController:
  enabled: true  # Set to false if you have existing ingress controller

# Use ingress for routing
ingress:
  enabled: true
  className: "nginx"
```

### **Custom Ingress Annotations**

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    # Add your custom annotations here
```

## 🌐 Access URLs

After deployment, your services will be available at:

| Service | URL | Description |
|---------|-----|-------------|
| **Application** | `http://<INGRESS_IP>/` | Main hotel reservation frontend |
| **API Gateway** | `http://<INGRESS_IP>/api/` | REST API endpoints |
| **Grafana** | `http://<INGRESS_IP>/grafana/` | Monitoring dashboards |
| **Prometheus** | `http://<INGRESS_IP>/prometheus/` | Metrics collection |
| **Jaeger** | `http://<INGRESS_IP>/jaeger/` | Distributed tracing |
| **Loki** | `http://<INGRESS_IP>/loki/` | Log aggregation |

### **Get Ingress IP**

```bash
# Get the LoadBalancer IP
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Or use this command
INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"
```

## 🔐 Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| **Grafana** | `admin` | `admin123` |

## 🔍 Verification Commands

### **Check Deployment Status**

```bash
# Check all pods
kubectl get pods -n hotel-reservation

# Check ingress resources
kubectl get ingress -n hotel-reservation

# Check ingress controller
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

### **Test Endpoints**

```bash
# Get ingress IP
INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test main application
curl -I http://$INGRESS_IP/

# Test API gateway
curl -I http://$INGRESS_IP/api/health

# Test Grafana
curl -I http://$INGRESS_IP/grafana/

# Test Prometheus
curl -I http://$INGRESS_IP/prometheus/
```

## 🛠️ Troubleshooting

### **Common Issues**

1. **LoadBalancer IP Pending**
   ```bash
   # Check cloud provider LoadBalancer provisioning
   kubectl describe svc ingress-nginx-controller -n ingress-nginx
   ```

2. **404 Not Found**
   ```bash
   # Check ingress rules
   kubectl describe ingress -n hotel-reservation
   
   # Check ingress controller logs
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   ```

3. **Grafana Subpath Issues**
   ```bash
   # Check Grafana configuration
   kubectl get configmap grafana-config -n hotel-reservation -o yaml
   
   # Check Grafana logs
   kubectl logs -n hotel-reservation -l app.kubernetes.io/name=grafana
   ```

### **Debug Commands**

```bash
# Check ingress controller status
kubectl get pods -n ingress-nginx

# View ingress controller configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf

# Test internal connectivity
kubectl exec -it deployment/grafana -n hotel-reservation -- curl -I http://localhost:3000/api/health
```

## 🔄 Updates and Maintenance

### **Update Ingress Controller**

```bash
# Update ingress controller
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --reuse-values
```

### **Update Application**

```bash
# Update application with new configuration
helm upgrade hotel-reservation ./helm/hotel-reservation-system \
  --namespace hotel-reservation \
  --values helm/hotel-reservation-system/values-aks.yaml
```

## 🎯 Benefits of This Setup

- ✅ **Single Entry Point**: One LoadBalancer for all services
- ✅ **Dynamic Routing**: Path-based routing without hardcoded IPs
- ✅ **Cost Effective**: Only one cloud LoadBalancer needed
- ✅ **SSL Ready**: Easy HTTPS setup with cert-manager
- ✅ **Scalable**: Built-in load balancing and health checks
- ✅ **Observable**: Integrated metrics and monitoring
- ✅ **Maintainable**: Clean separation of concerns

## 📚 Additional Resources

- [Nginx Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Helm Chart Dependencies](https://helm.sh/docs/helm/helm_dependency/)

---

🎉 **You're all set!** Your Hotel Reservation System is now running with a professional-grade ingress setup that automatically handles routing to all your services and observability tools.
