#!/bin/bash

set -e

echo ""
echo "$PWD"
echo ""

kubectl get ns red || kubectl create ns red

kubectl apply -f nginx-red-deployment.yaml
kubectl apply -f nginx-red-http-gw-api.yaml

sleep 5

./validate.sh
