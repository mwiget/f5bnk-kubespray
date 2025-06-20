#!/bin/bash

kubectl get f5-spk-vlans
until [ "$(kubectl get f5-spk-vlans | tail -n +2 | grep -cv 'CR config sent to all grpc endpoints')" -eq 0 ]; do
  echo "waiting for all f5-spk-vlans configured ..."
  kubectl get f5-spk-vlans
  sleep 5
done
kubectl get f5-spk-vlans
