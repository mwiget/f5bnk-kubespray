#!/bin/bash
set -e
template="bf.conf.template"

source ../.env
ubuntu_password=$(openssl passwd -1 "${DPU_CLEAR_PASSWORD}")

for node in $DPU_HOSTS; do
  filename="bf-${node}-dpu.conf"
  echo "$filename ..."
  cp $template $filename
  sed -i "s|^ubuntu_PASSWORD=.*|ubuntu_PASSWORD=\'$ubuntu_password\'|" $filename
  sed -i "s|^HOSTNAME=.*|HOSTNAME=\"$node-dpu\"|" $filename
  sed -i "s|^EXTERNAL_VLAN=.*|EXTERNAL_VLAN=$EXTERNAL_VLAN|" $filename
  sed -i "s|^MTU=.*|MTU=$MTU|" $filename
done
