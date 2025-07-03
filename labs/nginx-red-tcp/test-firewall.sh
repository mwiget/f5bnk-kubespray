#!/bin/bash
VIP=198.19.19.50
set -e


echo "testing http access to vip"
curl -o /dev/null -s -w "%{http_code}\n" http://$VIP

echo "applying firewall policy f5bigfwpolicy.yaml ..."
kubectl apply -f f5bigfwpolicy.yaml 
echo ""
sleep 1
kubectl get f5-big-fw-policy

echo ""
echo "testing http access to vip"
curl -o /dev/null -s -w "%{http_code}\n" --max-time 1 http://$VIP || echo "connection blocked"

echo ""
kubectl delete -f f5bigfwpolicy.yaml
