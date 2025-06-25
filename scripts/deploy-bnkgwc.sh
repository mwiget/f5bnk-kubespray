#!/bin/bash

set -e
SECONDS=0

set -a; source .env

echo "check cluster node ..."
kubectl get node -o wide

echo $INTERNAL_NETWORK

for node in $(kubectl get nodes -o name | grep -v dpu | cut -d/ -f2); do
  ip=$(kubectl get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
  echo -n "$node ($ip) -> k8s.ovn.org/node-primary-ifaddr="
  node_primary_ifaddr=$(ssh $ip "ip route get $INTERNAL_NETWORK 2>/dev/null | grep dev | awk '{print \$5}'")
  echo "$node_primary_ifaddr"
  kubectl annotate --overwrite node $node "k8s.ovn.org/node-primary-ifaddr={\"ipv4\":\"$node_primary_ifaddr\"}"
done

echo ""
echo "Install BIG-IP Next for Kubernetes BNKGatewayClass for host TMM ..."
kubectl apply -f resources/bnkgatewayclass.yaml

echo ""
echo "waiting for pods ready in f5-utils ..."
until kubectl wait --for=condition=Ready pods --all -n f5-utils; do
  echo "Waiting for pods to become Ready..."
  sleep 5
done
echo "All pods in f5-utils namespace are Ready."

echo ""
echo "waiting for f5-tmm daemonset be ready ..."
until [ "$(kubectl get daemonset f5-tmm -o jsonpath='{.status.numberReady}')" = "$(kubectl get daemonset f5-tmm -o jsonpath='{.status.desiredNumberScheduled}')" ]; do
  echo "Waiting for f5-tmm DaemonSet to be ready..."
  sleep 5
done
echo "f5-tmm DaemonSet is ready."

echo ""
echo "Installing vlan (selfIP) ..."
until kubectl apply -f resources/vlans.yaml; do
  echo "retrying in 5 secs ..."
  sleep 5
done

echo ""
echo "Install zebos bgp config  ..."
# BGP ConfigMap that includes ZebOS config
kubectl apply -f resources/zebos-bgp-cm.yaml

echo ""
echo "kubectl exec -ti ds/f5-tmm -c debug tmctl -d blade tmm/xnet/device_proved ..."
echo ""
kubectl exec -it ds/f5-tmm -c debug -- tmctl -d blade tmm/xnet/device_probed

echo ""
echo "kubectl exec -ti ds/f5-tmm -c debug -- ip -br a ..."
kubectl exec -ti ds/f5-tmm -c debug -- ip -br a

./scripts/check-f5-spk-vlans.sh

echo ""
echo "Deployment completed in $SECONDS secs"
