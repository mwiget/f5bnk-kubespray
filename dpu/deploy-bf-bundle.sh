#!/bin/bash
set -e

source ../.env

BFB_CONFIG=$1
if [ -z $BFB_CONFIG ]; then
  echo "Usage $0 <bf-<node>-dpu.conf>"
  exit 1
fi

if [ ! -e $BFB_IMAGE ]; then
  echo "downloading $BFB_IMAGE ..."
  wget -q --show-progress https://content.mellanox.com/BlueField/BFBs/Ubuntu22.04/$BFB_IMAGE
fi

node=$(echo "$BFB_CONFIG" | cut -d'-' -f2)
echo "uploading $BFB_IMAGE $BFB_CONFIG to $node ..."
rsync -avuz $BFB_IMAGE $BFB_CONFIG $node:

echo "remote installing image using config $BFB_CONFIG via $node ..."
ssh -t $node "sudo bfb-install --rshim rshim0 --config $BFB_CONFIG --bfb $BFB_IMAGE"

dpu="$node-dpu"

SECONDS=0
until ping -c1 -W1 $dpu >/dev/null 2>&1; do
  echo "Waiting $SECONDS secs for $dpu to be reachable..."
  sleep 10
done

echo "$dpu is reachable!"

# Resolve IP address from hostname
dpu_ip=$(getent hosts "$dpu" | awk '{ print $1 }')

# Sanity check
[ -z "$dpu_ip" ] && { echo "Failed to resolve IP for $dpu"; exit 1; }

# Clean up old SSH key entry by IP
ssh-keygen -R "$dpu_ip" >/dev/null 2>&1
ssh-keygen -R "$dpu" >/dev/null 2>&1

# Wait until ssh-copy-id succeeds
until sshpass -p "$DPU_CLEAR_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "ubuntu@$dpu"; do
   echo "sshpass -p $DPU_CLEAR_PASSWORD $dpu"
  echo "waiting for ssh-copy-id to succeed ..."
  sleep 1
  ssh-keygen -R "$dpu" >/dev/null 2>&1
done

echo ""
echo "Re-apply netplan on host ..."
ssh $node "sudo systemctl stop ovsdb-server; sudo netplan apply"
