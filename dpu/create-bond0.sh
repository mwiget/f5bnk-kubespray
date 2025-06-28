#!/bin/bash
echo "stopping openibd ..."
systemctl stop openibd
echo "deleting bond0 ..."
ip link del bond0
echo "starting openibd ..."
systemctl start openibd
echo "creating bond0 ..."
ip link add bond0 type bond
ip link set bond0 down
ip link set bond0 type bond miimon 100 mode 4 xmit_hash_policy layer3+4 lacp_rate fast
ip link set p0 down
ip link set p1 down
ip link set p0 master bond0
ip link set p1 master bond0
ip link set p0 up
ip link set p1 up
ip link set bond0 up
sleep 1
echo ""
echo "cat /proc/net/bonding/bond0"
echo ""
cat /proc/net/bonding/bond0
echo ""
ip link show dev bond0
