#!/bin/bash

echo "=== Checking Grafana Pod Status ==="
kubectl get pods -n observability -l app.kubernetes.io/name=grafana

echo -e "\n=== Checking Grafana Service ==="
kubectl get svc -n observability grafana

echo -e "\n=== Checking Grafana Service Details ==="
kubectl describe svc -n observability grafana

echo -e "\n=== Checking Grafana Pod Logs ==="
kubectl logs -n observability -l app.kubernetes.io/name=grafana --tail=20

echo -e "\n=== Checking if Grafana is Ready ==="
kubectl get pods -n observability -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.containerStatuses[0].ready}'

echo -e "\n=== Checking LoadBalancer External IP ==="
kubectl get svc -n observability grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

echo -e "\n=== Checking All Services in observability namespace ==="
kubectl get svc -n observability

echo -e "\n=== Port Forward Test (run this manually if needed) ==="
echo "kubectl port-forward -n observability svc/grafana 3000:3000"
