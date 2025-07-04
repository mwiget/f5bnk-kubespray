#!/usr/bin/env python3

import subprocess
import re
import sys

BRIDGE = sys.argv[1] if len(sys.argv) > 1 else "br-lag"
portmap = {}

# 1. Primary: ovs-ofctl show <bridge>
ofctl = subprocess.run(["ovs-ofctl", "show", BRIDGE], capture_output=True, text=True).stdout
for line in ofctl.splitlines():
    m = re.search(r'\s*(\d+)\(([^)]+)\):', line)
    if m:
        portmap[m.group(1)] = m.group(2)

# 2. Secondary: ovs-vsctl list Interface
vsctl = subprocess.run(["ovs-vsctl", "list", "Interface"], capture_output=True, text=True).stdout
ofport, ifname = None, None
for line in vsctl.splitlines():
    m = re.search(r'name\s*:\s*"([^"]+)"', line)
    if m:
        ifname = m.group(1)
    m = re.search(r'ofport\s*:\s*(-?\d+)', line)
    if m:
        ofport = m.group(1)
    if ifname and ofport:
        portmap.setdefault(ofport, ifname)
        ofport = None
        ifname = None

# 3. Fallback: ovs-dpctl show
dpctl = subprocess.run(["ovs-dpctl", "show"], capture_output=True, text=True).stdout
for line in dpctl.splitlines():
    m = re.match(r'\s*port\s+(\d+):\s+(\S+)', line)
    if m:
        portmap.setdefault(m.group(1), m.group(2))

# 4. Dump flows and rewrite in_port(N) with names
flows = subprocess.run(
    ["ovs-appctl", "dpctl/dump-flows", "type=offloaded"],
    capture_output=True, text=True
).stdout

for line in flows.strip().splitlines():
    line = re.sub(r'in_port\((\d+)\)', lambda m: f'in_port({portmap.get(m.group(1), "port" + m.group(1))})', line)
    print(line)
