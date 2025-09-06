#!/usr/bin/env bash
set -e
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
