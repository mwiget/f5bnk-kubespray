#!/bin/bash
for dpu in rome1-dpu milan1-dpu; do
  echo "$dpu ..."
  ssh $dpu "ifconfig -a | grep mtu"
  echo ""
done
