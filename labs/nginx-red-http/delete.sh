#!/bin/bash
set -e

kubectl delete -f nginx-red-http-gw-api.yaml || true
kubectl delete -f nginx-red-deployment.yaml || true
