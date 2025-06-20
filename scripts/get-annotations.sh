#!/bin/bash
kubectl get node -o json | jq '.items[] | {name: .metadata.name, annotations: .metadata.annotations}'
