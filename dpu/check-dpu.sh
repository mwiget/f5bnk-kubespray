#!/bin/bash
for dpu in rome1-dpu milan1-dpu; do
  echo "$dpu:"
  ssh rome1-dpu "sudo ovs-vsctl show; ip -br l; cat /proc/net/bonding/bond0"
  echo ""
done
