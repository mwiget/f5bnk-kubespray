#!/usr/bin/env bash
echo ""
echo "kubectl exec -ti ds/f5-tmm -c debug tmctl -d blade tmm/xnet/device_probed ..."
echo ""
kubectl exec -it ds/f5-tmm -c debug -- tmctl -d blade tmm/xnet/device_probed

echo ""
echo "kubectl exec -ti ds/f5-tmm -c debug -- ip -br a ..."
echo ""
kubectl exec -ti ds/f5-tmm -c debug -- ifconfig external
echo ""
kubectl exec -ti ds/f5-tmm -c debug -- ifconfig internal
echo ""
kubectl exec -ti ds/f5-tmm -c debug -- ip -br a

