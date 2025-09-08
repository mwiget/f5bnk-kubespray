## Link Aggregation via Nvidia Bluefield-3 DPU


```
+---------------------------------------------------------+---------------+
|                       Bluefield-3                       | Host Compute  |
| merged eSwitch             ovs-bridge br-lag            |     Linux     |
|----------------+----------------------------------------+---------------+
|                |        br-lag                          |               |
== p0            = bond0            pf0hpf <trunk port >  = enp193s0f0np0 |
|                |                                        |               |
|    eSwtich0    = en3f0pf0sf0 ---+                       |               |
|    (merged)    = en3f0pf0sf1    | pf0vf0 <push tag pop> = enp193s0f0v0  |
|    eSwitch1    = en3f0pf0sf2    | pf0vf1 <push tag pop> = enp193s0f0v1  |
|                = en3f0pf1sf0 -+ | pf0vf2 <push tag pop> = enp193s0f0v2  |
== p1            = en3f0pf1sf1  | | pf0vf3 <push tag pop> = enp193s0f0v3  |
|                = en3f1pf1sf2  | |                       |               |
+----------------+--------------|-|-----------------------+---------------+
|                      internal | | external              |
|                         +-----+-+-----+                 |
|                         |     TMM     |                 |
|                         +-------------+                 |
+---------------------------------------------------------+
```
         
Network bonding enables combining two or more network interfaces into a single interface. 
It increases the network throughput, bandwidth and provides redundancy if one of the interfaces fails.

NVIDIA BlueField DPU is configured for network bonding on the ARM side in a manner transparent to the host. 
Under this configuration, the host only sees a single PF (enp193s0f0np0). There is a mlnx config knob to
disable the 2nd PF (enp193s0f0np1), but that would break BNK GA 2.1 FLO validation.

pf0hpf connects with the first physical function (PF) on the host and passes all traffic, tagged and untagged.

Virtual Functions (VF) representors (pf0vf0, pf0vf1, ..) are configured with a VLAN tag (200 in this repo),
making them act like switch access ports: traffic from the ovs bridge with matching VLAN has the VLAN removed 
(POP) before passing to the host and traffic from the host to the ovs bridge gets VLAN added (push).

## Requirements

- Nvidia Bluefield-3 bf-bundle-2.9.2 bfb image. Use [./download-bf-bundle.sh](./download-bf-bundle.sh) to download
the image from Nvidia or use their official download side.
- Create bf.conf DPU configuration for each Bluefield-3 DPU. Use one of the example templates as starting point: 


## Image and configure Nvidia Bluefield-3 DPU's

- copy and adjust bf-firewall-jumbo.conf regarding MTU, ubuntu_password, VLAN
- copy your bf-firewall-jumbo.conf, console-dpu.sh and deploy-bf-bundle.sh to your whe  tag 210 pop> enp193s0f0np0f0v0
- on wf0orker node, execute ./deploy-bf-bundle.sh bf-firewall-jumbo.conf
- from another shell on the wf0orker node, monitor image progress with ./console-dpu.sh

### VLAN handling

The bf-firewall-jumbo.conf is static in nature and makes assumptions about MTU, VLAN (external and internal) 
and need to be adjusted:

- MTU is set to 9000
- External VLAN 210 has ovs firewall rules applied to protect from external/public
- Internal VLAN 200 is handled by ovs like access ports -> Host VFs are untagged
- VF's to the host are configured as access port with VLAN 200, allowing Pods to
attach via multus to VFs and be connected to internal VLAN 200 without specifying on the host.
- PF interface however passes all VLANs like a trunk port, allowing other VLANs be switched thru,
like storage. 

### Caveats

- DPU reboot will require re-applying netplan on the host, because the Virtual Functions (VF) disappear during the
process


### Check DPU bond0, MTU and ovs-vsctl status

```
./check-dpu.sh

6d9d789a-c2b9-48f3-af2c-ed34ad4e6e53
    Bridge br-lag
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
        Port pf0vf3
            tag: 200
            Interface pf0vf3
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port bond0
            Interface bond0
        Port pf0vf0
            tag: 200
            Interface pf0vf0
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port pf0hpf
            Interface pf0hpf
        Port pf0vf2
            tag: 200
            Interface pf0vf2
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port pf0vf1
            tag: 200
            Interface pf0vf1
        Port br-lag
            Interface br-lag
                type: internal
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
oob_net0         UP             5c:25:73:e6:38:68 <BROADCAST,MULTICAST,UP,LOWER_UP> 
tmfifo_net0      UP             00:1a:ca:ff:ff:11 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p0               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
p1               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
pf0hpf           UP             96:f4:1a:c7:c8:51 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf0           UP             62:e2:c7:4e:58:10 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf1           UP             8e:b3:03:42:8d:52 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf2           UP             ee:1d:a4:46:89:81 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf3           UP             8e:fc:d6:85:5a:01 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1hpf           UP             8e:e8:49:53:70:6c <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf0           UP             3a:4b:b8:40:0a:58 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf1           UP             4e:3d:63:42:59:52 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf2           UP             9a:94:69:7c:d4:d0 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf3           UP             9e:54:83:5b:d5:28 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf0      UP             52:0d:a3:68:88:7e <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s0       UP             02:c8:96:46:9c:38 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf1      UP             4a:4f:de:36:9c:aa <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf2      UP             7e:aa:b8:25:04:5f <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s2       UP             02:d9:76:1d:bd:f8 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf0      UP             32:fd:08:4e:ad:6a <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s0       UP             02:f8:49:62:de:e4 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf1      UP             72:c7:40:40:7c:8e <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf2      UP             1a:65:ab:da:c2:87 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s2       UP             02:f5:b2:00:ad:24 <BROADCAST,MULTICAST,UP,LOWER_UP> 
bond0            UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
ovs-system       DOWN           5e:b8:7f:0c:dc:16 <BROADCAST,MULTICAST> 
br-lag           UNKNOWN        5c:25:73:e6:38:54 <BROADCAST,MULTICAST,UP,LOWER_UP> 
kube-ipvs0       DOWN           b6:60:ca:c5:54:80 <BROADCAST,NOARP> 
vxlan.calico     UNKNOWN        66:0e:38:7c:ea:f6 <BROADCAST,MULTICAST,UP,LOWER_UP> 
nodelocaldns     DOWN           d6:c8:92:d0:7c:a8 <BROADCAST,NOARP> 
caliacf2a8953a0@if2 UP             ee:ee:ee:ee:ee:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
cali17a5d278cf6@if2 UP             ee:ee:ee:ee:ee:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
cali63ed86b1a54@if2 UP             ee:ee:ee:ee:ee:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
Ethernet Channel Bonding Driver: v5.15.0-1060-bluefield

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer3+4 (1)
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

802.3ad info
LACP active: on
LACP rate: fast
Min links: 0
Aggregator selection policy (ad_select): stable

Slave Interface: p0
MII Status: up
Speed: 200000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 5c:25:73:e6:38:54
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: none
Actor Churned Count: 0
Partner Churned Count: 0

Slave Interface: p1
MII Status: up
Speed: 200000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 5c:25:73:e6:38:55
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: none
Actor Churned Count: 0
Partner Churned Count: 0
bond0: flags=5187<UP,BROADCAST,RUNNING,MASTER,MULTICAST>  mtu 9000
br-lag: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
cali17a5d278cf6: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 8900
cali63ed86b1a54: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 8900
caliacf2a8953a0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 8900
en3f0pf0sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f0pf0sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f0pf0sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f1pf1sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f1pf1sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f1pf1sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
enp3s0f0s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f0s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
kube-ipvs0: flags=130<BROADCAST,NOARP>  mtu 1500
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
nodelocaldns: flags=130<BROADCAST,NOARP>  mtu 1500
oob_net0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
ovs-system: flags=4098<BROADCAST,MULTICAST>  mtu 1500
p0: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 9000
p1: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 9000
pf0hpf: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
pf0vf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
pf0vf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
pf0vf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
pf0vf3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
pf1hpf: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
tmfifo_net0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
vxlan.calico: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450

hw-offload:"true"

6d9d789a-c2b9-48f3-af2c-ed34ad4e6e53
    Bridge br-lag
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
        Port pf0vf3
            tag: 200
            Interface pf0vf3
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port bond0
            Interface bond0
        Port pf0vf0
            tag: 200
            Interface pf0vf0
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port pf0hpf
            Interface pf0hpf
        Port pf0vf2
            tag: 200
            Interface pf0vf2
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port pf0vf1
            tag: 200
            Interface pf0vf1
        Port br-lag
            Interface br-lag
                type: internal
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
```
