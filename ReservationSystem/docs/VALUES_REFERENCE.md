# Hotel Reservation System - Values Reference

This document provides a comprehensive reference for all configuration options available in the Helm chart's `values.yaml` file.

## 📋 Table of Contents

1. [Global Configuration](#global-configuration)
2. [Application Services](#application-services)
3. [Infrastructure Components](#infrastructure-components)
4. [Networking](#networking)
5. [Monitoring](#monitoring)
6. [Security](#security)

## 🌍 Global Configuration

### `global`

Global settings that apply to all components.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `global.namespace` | Kubernetes namespace for all resources | string | `"hotel-reservation"` |
| `global.environment` | Environment name (development/staging/production) | string | `"development"` |
| `global.imageRegistry` | Docker registry for all images | string | `""` |
| `global.imagePullPolicy` | Image pull policy for all containers | string | `"IfNotPresent"` |
| `global.imagePullSecrets` | Image pull secrets | array | `[]` |
| `global.storageClass` | Default storage class for PVCs | string | `""` |

#### Security Context
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `global.securityContext.runAsNonRoot` | Run containers as non-root user | boolean | `true` |
| `global.securityContext.runAsUser` | User ID to run containers | integer | `1000` |
| `global.securityContext.runAsGroup` | Group ID to run containers | integer | `3000` |
| `global.securityContext.fsGroup` | File system group ID | integer | `2000` |

## 🚀 Application Services

### Gateway Service

API Gateway and routing service built with Node.js/Express.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `gateway.enabled` | Enable Gateway service | boolean | `true` |
| `gateway.name` | Service name | string | `"gateway"` |
| `gateway.replicaCount` | Number of replicas | integer | `2` |

#### Image Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `gateway.image.repository` | Image repository | string | `"gateway"` |
| `gateway.image.tag` | Image tag | string | `"latest"` |
| `gateway.image.pullPolicy` | Image pull policy | string | `"IfNotPresent"` |

#### Service Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `gateway.service.type` | Service type | string | `"ClusterIP"` |
| `gateway.service.port` | Service port | integer | `9000` |
| `gateway.service.targetPort` | Container port | integer | `9000` |
| `gateway.service.annotations` | Service annotations | object | `{}` |

#### Resources
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `gateway.resources.requests.memory` | Memory request | string | `"256Mi"` |
| `gateway.resources.requests.cpu` | CPU request | string | `"250m"` |
| `gateway.resources.limits.memory` | Memory limit | string | `"512Mi"` |
| `gateway.resources.limits.cpu` | CPU limit | string | `"500m"` |

#### Health Probes
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `gateway.livenessProbe.httpGet.path` | Liveness probe path | string | `"/health"` |
| `gateway.livenessProbe.httpGet.port` | Liveness probe port | integer | `9000` |
| `gateway.livenessProbe.initialDelaySeconds` | Initial delay | integer | `30` |
| `gateway.livenessProbe.periodSeconds` | Check period | integer | `10` |
| `gateway.readinessProbe.httpGet.path` | Readiness probe path | string | `"/health"` |
| `gateway.readinessProbe.httpGet.port` | Readiness probe port | integer | `9000` |
| `gateway.readinessProbe.initialDelaySeconds` | Initial delay | integer | `5` |
| `gateway.readinessProbe.periodSeconds` | Check period | integer | `5` |

#### Environment Variables
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `gateway.env.NODE_ENV` | Node.js environment | string | `"production"` |
| `gateway.env.PORT` | Application port | string | `"9000"` |
| `gateway.env.LOG_LEVEL` | Logging level | string | `"info"` |

### Auth Service

Authentication and authorization service built with Java/Spring Boot.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `authService.enabled` | Enable Auth service | boolean | `true` |
| `authService.name` | Service name | string | `"auth-service"` |
| `authService.replicaCount` | Number of replicas | integer | `2` |

#### Image Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `authService.image.repository` | Image repository | string | `"auth-service"` |
| `authService.image.tag` | Image tag | string | `"latest"` |
| `authService.image.pullPolicy` | Image pull policy | string | `"IfNotPresent"` |

#### Service Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `authService.service.type` | Service type | string | `"ClusterIP"` |
| `authService.service.port` | Service port | integer | `8080` |
| `authService.service.targetPort` | Container port | integer | `8080` |

#### Environment Variables
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `authService.env.SPRING_PROFILES_ACTIVE` | Spring profiles | string | `"prod"` |
| `authService.env.SERVER_PORT` | Server port | string | `"8080"` |
| `authService.env.JWT_EXPIRATION` | JWT expiration time | string | `"86400"` |

### Search Service

Hotel search and filtering service built with Go/Gin.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `searchService.enabled` | Enable Search service | boolean | `true` |
| `searchService.name` | Service name | string | `"search-service"` |
| `searchService.replicaCount` | Number of replicas | integer | `2` |

#### Environment Variables
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `searchService.env.GIN_MODE` | Gin framework mode | string | `"release"` |
| `searchService.env.PORT` | Application port | string | `"8081"` |
| `searchService.env.CACHE_TTL` | Cache TTL in seconds | string | `"300"` |

### Booking Service

Reservation management service built with Python/FastAPI.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `bookingService.enabled` | Enable Booking service | boolean | `true` |
| `bookingService.name` | Service name | string | `"booking-service"` |
| `bookingService.replicaCount` | Number of replicas | integer | `2` |

#### Environment Variables
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `bookingService.env.ENVIRONMENT` | Application environment | string | `"production"` |
| `bookingService.env.PORT` | Application port | string | `"8000"` |
| `bookingService.env.LOG_LEVEL` | Logging level | string | `"INFO"` |

### Payment Service

Payment processing service built with Go/Gin.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `paymentService.enabled` | Enable Payment service | boolean | `true` |
| `paymentService.name` | Service name | string | `"payment-service"` |
| `paymentService.replicaCount` | Number of replicas | integer | `2` |

#### Environment Variables
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `paymentService.env.GIN_MODE` | Gin framework mode | string | `"release"` |
| `paymentService.env.PORT` | Application port | string | `"8082"` |
| `paymentService.env.PAYMENT_TIMEOUT` | Payment timeout | string | `"30s"` |

### Notification Service

Event-driven notification service built with Python/FastAPI.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `notificationService.enabled` | Enable Notification service | boolean | `true` |
| `notificationService.name` | Service name | string | `"notification-service"` |
| `notificationService.replicaCount` | Number of replicas | integer | `2` |

#### Environment Variables
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `notificationService.env.ENVIRONMENT` | Application environment | string | `"production"` |
| `notificationService.env.PORT` | Application port | string | `"8083"` |
| `notificationService.env.EMAIL_ENABLED` | Enable email notifications | string | `"true"` |

## 🗄️ Infrastructure Components

### PostgreSQL Auth

PostgreSQL database for authentication service.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `postgresAuth.enabled` | Enable PostgreSQL Auth | boolean | `true` |
| `postgresAuth.name` | StatefulSet name | string | `"postgres-auth"` |
| `postgresAuth.image.repository` | Image repository | string | `"postgres"` |
| `postgresAuth.image.tag` | Image tag | string | `"16-alpine"` |

#### Database Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `postgresAuth.database.name` | Database name | string | `"authdb"` |
| `postgresAuth.database.user` | Database user | string | `"authuser"` |
| `postgresAuth.database.password` | Database password | string | `"authpass"` |

#### Persistence
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `postgresAuth.persistence.enabled` | Enable persistence | boolean | `true` |
| `postgresAuth.persistence.size` | PVC size | string | `"10Gi"` |
| `postgresAuth.persistence.storageClass` | Storage class | string | `""` |

#### Resources
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `postgresAuth.resources.requests.memory` | Memory request | string | `"256Mi"` |
| `postgresAuth.resources.requests.cpu` | CPU request | string | `"250m"` |
| `postgresAuth.resources.limits.memory` | Memory limit | string | `"512Mi"` |
| `postgresAuth.resources.limits.cpu` | CPU limit | string | `"500m"` |

### PostgreSQL Booking

PostgreSQL database for booking service.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `postgresBooking.enabled` | Enable PostgreSQL Booking | boolean | `true` |
| `postgresBooking.name` | StatefulSet name | string | `"postgres-booking"` |
| `postgresBooking.database.name` | Database name | string | `"bookingdb"` |
| `postgresBooking.database.user` | Database user | string | `"bookinguser"` |
| `postgresBooking.database.password` | Database password | string | `"bookingpass"` |

### PostgreSQL Payment

PostgreSQL database for payment service.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `postgresPayment.enabled` | Enable PostgreSQL Payment | boolean | `true` |
| `postgresPayment.name` | StatefulSet name | string | `"postgres-payment"` |
| `postgresPayment.database.name` | Database name | string | `"paymentdb"` |
| `postgresPayment.database.user` | Database user | string | `"paymentuser"` |
| `postgresPayment.database.password` | Database password | string | `"paymentpass"` |

### MongoDB

Document database for hotels and notifications.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `mongodb.enabled` | Enable MongoDB | boolean | `true` |
| `mongodb.name` | StatefulSet name | string | `"mongodb"` |
| `mongodb.image.repository` | Image repository | string | `"mongo"` |
| `mongodb.image.tag` | Image tag | string | `"7.0"` |

#### Database Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `mongodb.database.name` | Database name | string | `"hoteldb"` |
| `mongodb.database.user` | Database user | string | `"hoteluser"` |
| `mongodb.database.password` | Database password | string | `"hotelpass"` |

### Redis

Caching and session storage.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `redis.enabled` | Enable Redis | boolean | `true` |
| `redis.name` | StatefulSet name | string | `"redis"` |
| `redis.image.repository` | Image repository | string | `"redis"` |
| `redis.image.tag` | Image tag | string | `"7.2-alpine"` |

#### Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `redis.config.maxmemory` | Maximum memory | string | `"256mb"` |
| `redis.config.maxmemory-policy` | Eviction policy | string | `"allkeys-lru"` |

### Kafka

Event streaming platform for booking events.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `kafka.enabled` | Enable Kafka | boolean | `true` |
| `kafka.name` | StatefulSet name | string | `"kafka"` |
| `kafka.image.repository` | Image repository | string | `"confluentinc/cp-kafka"` |
| `kafka.image.tag` | Image tag | string | `"7.5.0"` |

#### Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `kafka.config.KAFKA_NUM_PARTITIONS` | Default partitions | string | `"3"` |
| `kafka.config.KAFKA_DEFAULT_REPLICATION_FACTOR` | Replication factor | string | `"1"` |

### RabbitMQ

Message queuing for notifications.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `rabbitmq.enabled` | Enable RabbitMQ | boolean | `true` |
| `rabbitmq.name` | StatefulSet name | string | `"rabbitmq"` |
| `rabbitmq.image.repository` | Image repository | string | `"rabbitmq"` |
| `rabbitmq.image.tag` | Image tag | string | `"3.12-management-alpine"` |

#### Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `rabbitmq.config.RABBITMQ_DEFAULT_USER` | Default user | string | `"admin"` |
| `rabbitmq.config.RABBITMQ_DEFAULT_PASS` | Default password | string | `"admin123"` |

### Zookeeper

Coordination service for Kafka.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `zookeeper.enabled` | Enable Zookeeper | boolean | `true` |
| `zookeeper.name` | StatefulSet name | string | `"zookeeper"` |
| `zookeeper.image.repository` | Image repository | string | `"confluentinc/cp-zookeeper"` |
| `zookeeper.image.tag` | Image tag | string | `"7.5.0"` |

## 🌐 Networking

### Ingress

External access configuration.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `ingress.enabled` | Enable Ingress | boolean | `false` |
| `ingress.className` | Ingress class name | string | `""` |
| `ingress.annotations` | Ingress annotations | object | `{}` |

#### Hosts Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `ingress.hosts[0].host` | Hostname | string | `"hotel.local"` |
| `ingress.hosts[0].paths[0].path` | Path | string | `"/"` |
| `ingress.hosts[0].paths[0].pathType` | Path type | string | `"Prefix"` |
| `ingress.hosts[0].paths[0].service` | Backend service | string | `"gateway"` |
| `ingress.hosts[0].paths[0].port` | Backend port | integer | `9000` |

#### TLS Configuration
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `ingress.tls[0].secretName` | TLS secret name | string | `"hotel-reservation-tls"` |
| `ingress.tls[0].hosts[0]` | TLS hostname | string | `"hotel.local"` |

### Network Policy

Network isolation configuration.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `networkPolicy.enabled` | Enable Network Policies | boolean | `false` |

## 📊 Monitoring

### Service Monitor

Prometheus monitoring configuration.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `serviceMonitor.enabled` | Enable ServiceMonitor | boolean | `false` |
| `serviceMonitor.namespace` | Monitor namespace | string | `"monitoring"` |
| `serviceMonitor.interval` | Scrape interval | string | `"30s"` |
| `serviceMonitor.scrapeTimeout` | Scrape timeout | string | `"10s"` |
| `serviceMonitor.labels` | Additional labels | object | `{}` |

### Horizontal Pod Autoscaler

Auto-scaling configuration.

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `hpa.enabled` | Enable HPA | boolean | `false` |
| `hpa.minReplicas` | Minimum replicas | integer | `2` |
| `hpa.maxReplicas` | Maximum replicas | integer | `10` |
| `hpa.targetCPUUtilizationPercentage` | CPU target | integer | `70` |
| `hpa.targetMemoryUtilizationPercentage` | Memory target | integer | `80` |

## 🔒 Security

All services inherit security settings from `global.securityContext`. Individual services can override these settings if needed.

### Pod Security Context
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `<service>.securityContext.runAsNonRoot` | Run as non-root | boolean | `true` |
| `<service>.securityContext.runAsUser` | User ID | integer | `1000` |
| `<service>.securityContext.runAsGroup` | Group ID | integer | `3000` |
| `<service>.securityContext.fsGroup` | File system group | integer | `2000` |

### Container Security Context
| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `<service>.containerSecurityContext.allowPrivilegeEscalation` | Allow privilege escalation | boolean | `false` |
| `<service>.containerSecurityContext.readOnlyRootFilesystem` | Read-only root filesystem | boolean | `true` |
| `<service>.containerSecurityContext.capabilities.drop` | Dropped capabilities | array | `["ALL"]` |

---

This reference covers all major configuration options. For specific use cases or advanced configurations, refer to the [Deployment Guide](HELM_DEPLOYMENT_GUIDE.md) or examine the complete `values.yaml` file.
