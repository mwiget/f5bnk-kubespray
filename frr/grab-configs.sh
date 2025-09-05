#!/bin/bash
for node in rome1 milan1; do
  echo "$node ..."
  scp $node:/etc/frr/frr.conf frr-${node}.conf
done
