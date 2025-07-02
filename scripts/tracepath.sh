#!/bin/bash
node="rome1"
for destination in 198.18.100.73 192.0.2.73; do
  echo "$node to $destination ..."
  ssh $node "tracepath $destination"
done
