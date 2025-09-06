#!/usr/bin/env bash

set -e

echo ""
echo "check presence of ~/far/f5-far-auth-key.gz auth key and JWT Token ~/.jwt ..."

test -e ~/far/f5-far-auth-key.tgz || (echo "Please download far-f5-auth-key.tz from myf5.com into ~/far/" && exit 1)
test -e ~/.jwt || (echo "Please store your JWT token in ~/.jwt, required todeploy resources/bnk-infrastructure.yaml" && exit 1)

echo ""
echo "check cluster ..."

if ! kubectl get nodes >/dev/null 2>&1; then
  echo "cluster not found. Please run ./create-k3s-cluster.sh"
  exit 1
fi

echo ""
echo -n "check NFS server referenced in resources/storageclass.yaml ..."

YAML_FILE="resources/storageclass.yaml"
# Extract server and share path from YAML file
server=$(awk '/server:/ { print $2 }' "$YAML_FILE")
share=$(awk '/share:/ { print $2 }' "$YAML_FILE")

if [[ -z "$server" || -z "$share" ]]; then
  echo ""
  echo "Error: Could not extract server or share path from $YAML_FILE"
  exit 1
else 
  echo "yes"
fi

echo -n "check NFS export $share on server $server based on $YAML_FILE ... "

# Get exported paths
found=$(showmount -e "$server" 2>/dev/null | awk 'NR > 1 { print $1 }' | grep $share)
if [[ -n "$found" ]]; then
  echo "yes"
else
  echo ""
  echo "ERROR: Share $share is NOT within exported paths on $server"
  exit 1
fi

echo ""
manifest="resources/sriovdp-config.yaml"
echo "check existence of pfNames in $manifest ..."

echo "Checking if pfNames from $manifest exist on this host ..."
for pf in $(grep pfNames $manifest| grep enp | cut -d\" -f4); do
  if ! ip link show "$pf" > /dev/null 2>&1; then
    echo ""
    echo "WARNING: pfName $pf from $manifest does not exist on this host." >&2
  else
    echo "$pf"
  fi
done

echo "requirements ok"
