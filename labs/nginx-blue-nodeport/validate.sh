#!/bin/bash
NAMESPACE="blue"
set -e

client=lake1    # host with route to external BNK interface p0
ip="198.18.100.62"

echo ""
set +x
kubectl get services -n $NAMESPACE

echo ""
echo "Test with curl from client $client ..."
echo ""
ssh $client curl -Is http://$ip:30080

echo ""
echo "Downloading 512kb payload from $ip ..."
ssh $client "curl -s -w \"\nTime: %{time_total}s\nSpeed: %{speed_download} bytes/s\n\" -o /dev/null http://$ip:30080/test/512kb"
