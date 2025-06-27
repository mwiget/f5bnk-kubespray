#!/bin/bash
set -e

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30088 \
  --set controller.service.nodePorts.https=30443

until kubectl rollout status deployment/ingress-nginx-controller --timeout=5s; do
  echo "Waiting for ingress-nginx-controller to be ready..."
  sleep 5
done

kubectl apply -f ingress-resource.yaml 
