#!/bin/bash

set -e

echo ""
echo "$PWD"
echo ""

kubectl get ns red || kubectl create ns red

kubectl apply -f nginx-red-deployment.yaml
kubectl apply -f nginx-red-tcp-gw-api.yaml

until kubectl wait --for=condition=Ready pods --all -n red; do
  echo "trying again in 5 secs ..."
  echo "sleep 5"
done
#./validate.sh
