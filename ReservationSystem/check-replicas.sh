#!/bin/bash

echo "=== Current Deployments and Replica Counts ==="
kubectl get deployments -n hotel-reservation -o custom-columns="NAME:.metadata.name,REPLICAS:.spec.replicas,READY:.status.readyReplicas"

echo -e "\n=== Current Values from Helm Release ==="
helm get values hotel-reservation -n hotel-reservation

echo -e "\n=== Checking specific services with 2 replicas ==="
kubectl get deployments -n hotel-reservation -o json | jq -r '.items[] | select(.spec.replicas == 2) | .metadata.name'

echo -e "\n=== Checking ReplicaSets ==="
kubectl get replicasets -n hotel-reservation -o custom-columns="NAME:.metadata.name,REPLICAS:.spec.replicas,READY:.status.readyReplicas"

echo -e "\n=== Checking if there are any HPA (Horizontal Pod Autoscaler) ==="
kubectl get hpa -n hotel-reservation

echo -e "\n=== Checking for any StatefulSets ==="
kubectl get statefulsets -n hotel-reservation -o custom-columns="NAME:.metadata.name,REPLICAS:.spec.replicas,READY:.status.readyReplicas"
