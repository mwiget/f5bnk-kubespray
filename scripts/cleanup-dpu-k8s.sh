#!/bin/bash
nodes=$(scripts/get-dpu-names.sh $1)
echo "$nodes ..."

for node in $nodes; do
  scp dpu/cleanup-k8s.sh $node:
  ssh $node ./cleanup-k8s.sh
done
