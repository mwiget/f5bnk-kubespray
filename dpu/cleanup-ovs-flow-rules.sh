#!/bin/bash
set -e

BRIDGE="br-lag"
IN_PORT="bond0"

echo "🧹 Deleting OpenFlow rules for VLAN 210 on $BRIDGE..."

# Delete all rules that match VLAN 210 on ingress from bond0
ovs-ofctl dump-flows "$BRIDGE" | \
  awk -F, -v br="$BRIDGE" -v port="$IN_PORT" '
    /dl_vlan=210/ && $0 ~ "in_port=" port {
      gsub(".*cookie=", "cookie=", $0);  # trim front
      cmd = "ovs-ofctl --strict del-flows " br " \"" $0 "\""
      print "❌ Removing: " cmd
      system(cmd)
    }
  '

# Optionally delete lower-priority catchall drop rule (for VLAN 210)
ovs-ofctl --strict del-flows "$BRIDGE" "in_port=$IN_PORT,dl_vlan=210"

echo "✅ Cleanup complete. VLAN 210 flows removed."
