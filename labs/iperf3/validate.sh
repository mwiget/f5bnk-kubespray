#!/bin/bash

set -e

#for node in rome1 milan1; do
for node in milan1; do
  #echo "hack: adding static route for VIP /24 via milan1 on rome1 ..."
  ssh $node sudo ip route del 198.19.19.0/24 || true
  # ssh milan1 sudo ip route add 198.19.19.0/24 via 198.18.100.202 || true # via internal
  ssh $node sudo ip route add 198.19.19.0/24 via 192.0.2.202 || true # via external
  echo "\nchecking max MTU (tracepath) from $node via rome1 ..."
  ssh $node stdbuf -oL tracepath -m 2 198.19.19.51
  echo "\nrunning iperf3 from $node via rome1 192.0.2.202 ..."
  ssh $node stdbuf -oL iperf3 -t 10 -c 198.19.19.51 -P 16
done
