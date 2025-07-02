#!/bin/bash

set -e

echo "hack: adding static route to local BGP router"
sudo ip route add 198.19.19.0/24 via 192.168.68.65 || true

echo "" set -x
kubectl get f5-bnkgateways
kubectl get gatewayclass f5-gateway-class
kubectl get gateway -n red f5-l4-gateway
kubectl get l4route -n red
kubectl get services -n red
set +x
echo ""

#echo ""
#vip=$(kubectl get svc -n red nginx-app-svc -o jsonpath='{.spec.clusterIP}')
#echo "Test nginx service via clusterIP $vip ..."
#until curl -Is http://$vip; do
#  echo "waiting 5 secs and try again ..."
#  sleep 5
#done

echo ""
echo "extract assigned IP address from f5-l4-gateway and check route ... "
vip=$(kubectl get gateway -n red f5-l4-gateway -o json | jq -r '.status.addresses[] | select(.type == "IPAddress") | .value')
ip r get $vip

echo "vip=$vip"

echo ""
echo "$PWD"
echo ""
echo "Test reachability to virtual server $vip from $client ..."
until ping -c3 $vip; do
  echo "waiting 10 secs and try again ..."
  sleep 10
done

echo ""
echo "Test with curl from client $client ..."
echo ""
curl -Is http://$vip

echo ""
echo "Downloading 512kb payload from $vip ..."
set -x
curl -s -w "\nTime: %{time_total}s\nSpeed: %{speed_download} bytes/s\n" -o /dev/null http://$vip/test/512kb
set +x
