#!/bin/bash

set -e

echo ""
echo "$PWD"
echo ""

kubectl get ns blue || kubectl create ns blue
sleep 2
kubectl apply -f nginx-blue-deployment.yaml
kubectl apply -f nginx-app-nodeport.yaml

sleep 5
./validate.sh
