#!/bin/bash
netplanconfig="10-bnk-config.yaml"
for node in rome1 milan1; do
  echo "$node ..."
  ssh $node "sudo cp /etc/netplan/$netplanconfig /tmp/ && sudo chmod a+r /tmp/$netplanconfig"
  scp $node:/tmp/$netplanconfig "10-$node-bnk-config.yaml"
done
