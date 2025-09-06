#!/usr/bin/env bash

# Script to uninstall all Helm releases across all namespaces
# Use with caution!

echo "Uninstalling all Helm releases..."

RELEASES=$(helm ls -A -q)

for RELEASE in $RELEASES; do
  NAMESPACE=$(helm ls -A | grep "^$RELEASE" | awk '{print $2}')
  echo "Uninstalling release: $RELEASE from namespace: $NAMESPACE"
  helm uninstall "$RELEASE" -n "$NAMESPACE"
done

echo "All Helm releases uninstalled."
