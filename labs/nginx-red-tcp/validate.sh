#!/bin/bash

set -e

echo ""
set -x
kubectl get f5-bnkgateways
kubectl get gatewayclass f5-gateway-class
kubectl get gateway -n red f5-l4-gateway
kubectl get l4route -n red
kubectl get services -n red
set +x
echo ""

echo ""
cip=$(kubectl get svc -n red nginx-app-svc -o jsonpath='{.spec.clusterIP}')
echo "Test nginx service via clusterIP $cip ..."
until curl -Is http://$cip; do
  echo "waiting 5 secs and try again ..."
  sleep 5
done

echo ""
echo "extract assigned IP address from f5-l4-gateway and check route ... "
ip=$(kubectl get gateway -n red f5-l4-gateway -o json | jq -r '.status.addresses[] | select(.type == "IPAddress") | .value')
ip r get $ip

#echo ""
#ip -br a show |grep enp |grep -v v

echo ""
echo "$PWD"
echo ""
echo "Test reachability to virtual server $ip from $client ..."
until ping -c3 $ip; do
  echo "waiting 10 secs and try again ..."
  sleep 10
done

echo ""
echo "Test with curl from client $client ..."
echo ""
curl -Is http://$ip

echo ""
echo "Downloading 512kb payload directly from $cip ..."
set -x
curl -s -w "\nTime: %{time_total}s\nSpeed: %{speed_download} bytes/s\n" -o /dev/null http://$cip/test/512kb
set +x

echo ""
echo "Downloading 512kb payload from $ip ..."
set -x
curl -s -w "\nTime: %{time_total}s\nSpeed: %{speed_download} bytes/s\n" -o /dev/null http://$ip/test/512kb
set +x
