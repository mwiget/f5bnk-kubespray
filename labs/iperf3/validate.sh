#!/bin/bash

set -e

#echo "hack: adding static route for VIP /24 via milan1 on rome1 ..."
ssh rome1 sudo ip route del 198.19.19.0/24 || true
ssh rome1 sudo ip route add 198.19.19.0/24 via 198.18.100.202 || true

echo "\nrunning iperf3 via 198.18.100.202 ..."
ssh rome1 iperf3 -t 5 -c 198.19.19.51

echo "hack: adding static route for VIP /24 via milan1 on rome1 ..."
#ssh rome1 sudo ip route del 198.19.19.0/24 || true
#ssh rome1 sudo ip route add 198.19.19.0/24 via 198.18.100.201 || true

#echo "\nrunning iperf3 via 198.18.100.201 ..."
#ssh rome1 iperf3 -t 5 -c 198.19.19.51

