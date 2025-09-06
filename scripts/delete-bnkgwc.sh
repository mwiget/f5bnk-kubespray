#!/usr/bin/env bash

set -e


if ! kubectl get nodes >/dev/null 2>&1; then
  echo "cluster not found. Please run make first"
  exit 1
fi

kubectl delete -f resources/bnkgatewayclass.yaml
