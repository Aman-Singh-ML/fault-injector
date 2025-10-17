#!/bin/bash

echo "=== Checking Helm Release Status ==="
helm status hotel-reservation -n hotel-reservation

echo -e "\n=== Checking All Pods in hotel-reservation namespace ==="
kubectl get pods -n hotel-reservation -o wide

echo -e "\n=== Checking All Pods in observability namespace ==="
kubectl get pods -n observability -o wide

echo -e "\n=== Checking All Namespaces ==="
kubectl get namespaces

echo -e "\n=== Checking Deployments in hotel-reservation ==="
kubectl get deployments -n hotel-reservation

echo -e "\n=== Checking Deployments in observability ==="
kubectl get deployments -n observability

echo -e "\n=== Checking Services in hotel-reservation ==="
kubectl get services -n hotel-reservation

echo -e "\n=== Checking Services in observability ==="
kubectl get services -n observability

echo -e "\n=== Checking if observability templates are being rendered ==="
helm template hotel-reservation ./helm/hotel-reservation-system \
  --values helm/hotel-reservation-system/values-aks.yaml \
  --show-only templates/observability/jaeger/jaeger-deployment.yaml | head -20

echo -e "\n=== Checking Helm values for observability ==="
helm get values hotel-reservation -n hotel-reservation
