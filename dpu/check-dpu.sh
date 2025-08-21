#!/bin/bash

# show ovs bridge(s), bond0 member links status and interface mtu
# from all DPU's in the hosts listed in ../.env
#
source ../.env
for node in $DPU_HOSTS; do
  dpu="$node-dpu"
  echo "$dpu:"
  ssh rome1-dpu "sudo ovs-vsctl show; ip -br l; cat /proc/net/bonding/bond0; ifconfig -a |grep mtu"
  echo ""
done
