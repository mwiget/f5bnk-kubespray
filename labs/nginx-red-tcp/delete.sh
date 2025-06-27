#!/bin/bash
set -e

kubectl delete -f nginx-red-tcp-gw-api.yaml || true
kubectl delete -f nginx-red-deployment.yaml || true
