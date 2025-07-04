#!/bin/bash
set -e

BRIDGE="br-lag"
IN_PORT="bond0"  # ingress interface for VLAN 210 traffic

echo "🔄 Clearing all OpenFlow rules on $BRIDGE..."
ovs-ofctl del-flows "$BRIDGE"

echo "✅ Installing VLAN 210 allow rules for ARP, ICMP, SSH, HTTP, HTTPS, BGP..."

# === IPv4 Rules ===

# ARP
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x0806,actions=NORMAL"

# IPv4 - SSH
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x0800,nw_proto=6,tp_dst=22,actions=NORMAL"

# IPv4 - HTTP
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x0800,nw_proto=6,tp_dst=80,actions=NORMAL"

# IPv4 - HTTPS
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x0800,nw_proto=6,tp_dst=443,actions=NORMAL"

# IPv4 - BGP
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x0800,nw_proto=6,tp_dst=179,actions=NORMAL"

# IPv4 - ICMP
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x0800,nw_proto=1,actions=NORMAL"

# === IPv6 Rules ===

# IPv6 - SSH
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x86dd,nw_proto=6,tp_dst=22,actions=NORMAL"

# IPv6 - HTTP
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x86dd,nw_proto=6,tp_dst=80,actions=NORMAL"

# IPv6 - HTTPS
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x86dd,nw_proto=6,tp_dst=443,actions=NORMAL"

# IPv6 - BGP
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x86dd,nw_proto=6,tp_dst=179,actions=NORMAL"

# IPv6 - ICMPv6 (ND, ping, RA, RS, etc.)
ovs-ofctl add-flow "$BRIDGE" \
  "priority=200,in_port=$IN_PORT,dl_vlan=210,dl_type=0x86dd,nw_proto=58,actions=NORMAL"

# === Deny other traffic on VLAN 210 ===

ovs-ofctl add-flow "$BRIDGE" \
  "priority=100,in_port=$IN_PORT,dl_vlan=210,actions=drop"

# === Allow all other traffic (non-VLAN 210) ===

ovs-ofctl add-flow "$BRIDGE" \
  "priority=0,actions=NORMAL"

echo "✅ Done. VLAN 210 now permits ARP, ICMP, SSH, HTTP, HTTPS, BGP for both IPv4 and IPv6."
