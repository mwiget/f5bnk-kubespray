#!/bin/bash
REPLICAS=10
DURATION=${1:-10s}
CONCURRENT_REQUESTS=100
THREADS=10
VIP="198.19.19.50"
#VIP="198.19.19.100"
NAMESPACE=red
DEPLOYMENT=nginx-deployment

client=rome1

set -e

ssh $client sudo ip route del 198.19.19.0/24 || true
ssh $client sudo ip route add 198.19.19.0/24 via 198.18.100.202 || true


echo "scaling $DEPLOYMENT to $REPLICAS replicas ..."
kubectl scale deployment $DEPLOYMENT -n $NAMESPACE --replicas=$REPLICAS


while true; do
    spec_replicas=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    ready_replicas=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')

    if [ "$spec_replicas" -eq "$REPLICAS" ] && [ "$ready_replicas" -eq "$REPLICAS" ]; then
        echo "Success: $REPLICAS replicas are configured and ready."
        break
    else
        echo "Waiting: $spec_replicas configured, $ready_replicas ready. Retrying in 5s..."
        sleep 5
    fi
done

echo ""
kubectl get deployment -n $NAMESPACE $DEPLOYMENT
echo ""

echo "single request (small packet) ..."
set -x
ssh $client "curl -s -w \"\nTime: %{time_total}s\nSpeed: %{speed_download} bytes/s\n\" -o /dev/null http://$VIP"

echo "single request (512kb) ..."
set -x
ssh $client "curl -s -w \"\nTime: %{time_total}s\nSpeed: %{speed_download} bytes/s\n\" -o /dev/null http://$VIP/test/512kb"

echo ""
echo "Sending $CONCURRENT_REQUESTS for $DURATION ..."
ssh $client "wrk -t$THREADS -c$CONCURRENT_REQUESTS -d$DURATION --latency http://$VIP/test/512kb"
