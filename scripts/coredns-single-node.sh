#!/usr/bin/env bash
set -e

# Count the number of non-BlueField nodes
non_bf_count=$(kubectl get node -o wide | grep -v bluefield | tail -n +2 | wc -l)

# Check if the count is greater than 1
if [ "$non_bf_count" -gt 1 ]; then
  echo "More than one non-BlueField node detected ($non_bf_count). No change needed"
  exit 0
fi
echo "add toleration to allow coredns on dpu .."
kubectl -n kube-system patch deployment coredns \
  --type=json \
  -p='[{"op": "add", "path": "/spec/template/spec/tolerations", "value": [{"key": "dpu", "operator": "Equal", "value": "true", "effect": "NoSchedule"}]}]'
