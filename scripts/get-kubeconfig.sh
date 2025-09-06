#!/usr/bin/env bash
set -e

set -a; source ./.env
INVENTORY_FILE="inventory/$CLUSTER/inventory.yaml"
first_ansible_host=$(yq '.all.hosts | to_entries | .[0].value.ansible_host' "$INVENTORY_FILE")

echo "$first_ansible_host ..."

ssh  $first_ansible_host "sudo cp /etc/kubernetes/admin.conf /tmp && sudo chmod a+r /tmp/admin.conf"
mkdir -p ~/.kube
scp $first_ansible_host:/tmp/admin.conf ~/.kube/config

ssh $first_ansible_host "sudo rm -f /tmp/admin.conf"
sed -i.bak "s/127\\.0\\.0\\.1/$first_ansible_host/g" ~/.kube/config
kubectl get node -o wide
