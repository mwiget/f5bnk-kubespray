#!/bin/bash
kubectl delete -f resources/sriovdp-config.yaml
kubectl apply -f resources/sriovdp-config.yaml
kubectl -n kube-system rollout restart ds/kube-sriov-device-plugin-amd64
