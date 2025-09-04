#!/bin/bash

set -e

echo ""
echo "$PWD"
echo ""

kubectl apply -f iperf3-deployment.yaml

until kubectl wait --for=condition=Ready pods --all -n iperf3; do
  echo "trying again in 5 secs ..."
  echo "sleep 5"
done

kubectl apply -f gateway-lb-l4route.yaml
./create-backends.sh

echo -e "\nGateway status:"
kubectl -n default get gateway f5-l4-gateway -o wide || true
echo -e "\nL4Route status:"
kubectl -n iperf3 get l4route iperf3-route -o yaml | sed -n '/status:/,$p' || true
echo -e "\nL4Route Endpoints:"
kubectl -n iperf3  get Endpoints

echo -e "\niperf3 pods:"
kubectl  get pod -n iperf3 -o wide
#./validate.sh
