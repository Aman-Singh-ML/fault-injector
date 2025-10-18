#!/bin/bash

# Script to rebuild and push Docker images for services with metrics fixes

set -e

echo "🔨 Rebuilding services with Kafka metrics instrumentation..."

# Booking Service
echo ""
echo "📦 Building booking-service..."
cd services/booking-service
docker build -t amansingh2708/booking-service:latest .
echo "⬆️  Pushing booking-service..."
docker push amansingh2708/booking-service:latest
cd ../..

# Notification Service
echo ""
echo "📦 Building notification-service..."
cd services/notification-service
docker build -t amansingh2708/notification-service:latest .
echo "⬆️  Pushing notification-service..."
docker push amansingh2708/notification-service:latest
cd ../..

echo ""
echo "✅ All services rebuilt and pushed successfully!"
echo ""
echo "Next steps:"
echo "1. Deploy updated Helm chart:"
echo "   helm upgrade hotel-reservation ./helm/hotel-reservation-system \\"
echo "     --namespace hotel-reservation \\"
echo "     --values helm/hotel-reservation-system/values.yaml \\"
echo "     --wait --timeout 15m"
echo ""
echo "2. Restart Grafana:"
echo "   kubectl rollout restart deployment/grafana -n hotel-reservation"
echo ""
echo "3. Restart services:"
echo "   kubectl rollout restart deployment/booking-service -n hotel-reservation"
echo "   kubectl rollout restart deployment/notification-service -n hotel-reservation"
echo ""
echo "4. Verify metrics:"
echo "   kubectl port-forward -n hotel-reservation svc/booking-service 8000:8000"
echo "   curl http://localhost:8000/metrics | grep kafka_messages_total"

