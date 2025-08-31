#!/bin/bash

node=$1
[ -z "$node" ] && { echo "Usage: $0 <node>"; exit 1; }
ssh $node "sudo ovs-vsctl show; ip -br l; cat /proc/net/bonding/bond0; ifconfig -a |grep mtu; sudo ovs-vsctl get Open_vSwitch . other_config:hw-offload"
