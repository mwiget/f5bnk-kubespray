#!/bin/bash
set -e

kubectl delete -f nginx-app-nodeport.yaml || true
kubectl delete -f nginx-blue-deployment.yaml || true
