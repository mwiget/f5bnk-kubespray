#!/usr/bin/env bash
set -euo pipefail

BACKENDS=$(kubectl get pod -o json -n iperf3 | jq '.items[] | {name: .metadata.name, annotations: .metadata.annotations}' \
	| jq -c '. as $pod | .annotations."k8s.v1.cni.cncf.io/network-status" | fromjson | 
      {name: $pod.name, eth0: .[0].ips[0], net1: (.[1].ips[0] // "N/A")}' | jq -r '.net1'| grep -v N\/A)

echo "backends: $BACKENDS"

# Endpoints for IP backends ===
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Endpoints
metadata:
  name: iperf3-backend
  namespace: iperf3
subsets:
  - addresses:
$(for be in ${BACKENDS}; do ip="${be%%:*}"; port="\${be##*:}"; echo "      - ip: ${ip}"; done)
    ports:
      - name: tcp-5201
        port: 5201
        protocol: TCP
EOF

