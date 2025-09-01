## Image and configure Nvidia Bluefield-3 DPU's

- copy and adjust bf-firewall-jumbo.conf regarding MTU, ubuntu_password, VLAN
- copy your bf-firewall-jumbo.conf, console-dpu.sh and deploy-bf-bundle.sh to your worker node with the dpu
- on worker node, execute ./deploy-bf-bundle.sh bf-firewall-jumbo.conf
- from another shell on the worker node, monitor image progress with ./console-dpu.sh


### Caveats

- VLAN host interfaces get removed during the DPU imaging process. Re-apply by running `sudo netplan apply` on the 
host. Script deploy-bf-bundle.sh does it automatically, but worth checking if all interfaces are present on the host.

### Check DPU bond0, MTU and ovs-vsctl status

```
./chec-dpu.sh

53346a65-f58e-4f8b-93c4-77ae4394e14f
    Bridge br-lag
        Port bond0
            Interface bond0
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port br-lag
            Interface br-lag
                type: internal
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port pf0hpf
            Interface pf0hpf
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
oob_net0         UP             5c:25:73:e6:38:68 <BROADCAST,MULTICAST,UP,LOWER_UP> 
tmfifo_net0      UP             00:1a:ca:ff:ff:11 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p0               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
p1               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
pf0hpf           UP             3a:11:ca:10:d1:cd <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf0           UP             8e:0c:2d:90:bc:22 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf1           UP             06:28:f5:8d:3f:e6 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf2           UP             3e:06:c3:1a:6b:84 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf3           UP             3e:87:01:f0:a7:b1 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1hpf           UP             d2:b1:a9:93:ab:ec <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf0           UP             4a:a8:fa:7e:98:d9 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf1           UP             ee:f0:74:15:4c:b9 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf2           UP             82:ca:6d:92:ef:4f <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf3           UP             82:a5:ce:9a:05:63 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf0      UP             0a:63:76:83:64:a6 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s0       UP             02:b8:d6:bf:5c:c7 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf1      UP             76:55:db:39:5f:63 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf2      UP             4e:a6:8a:60:03:d1 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s2       UP             02:2f:0f:eb:0c:7c <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf0      UP             2e:41:7c:f4:27:1c <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s0       UP             02:dc:df:3d:fe:79 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf1      UP             66:f2:3c:0e:15:bd <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf2      UP             a2:28:17:d6:fe:ec <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s2       UP             02:e9:b7:72:c2:95 <BROADCAST,MULTICAST,UP,LOWER_UP> 
bond0            UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
ovs-system       DOWN           62:88:8e:5c:cd:a8 <BROADCAST,MULTICAST> 
br-lag           UNKNOWN        5c:25:73:e6:38:54 <BROADCAST,MULTICAST,UP,LOWER_UP> 
kube-ipvs0       DOWN           ca:e1:7e:8d:23:20 <BROADCAST,NOARP> 
vxlan.calico     UNKNOWN        66:0e:38:7c:ea:f6 <BROADCAST,MULTICAST,UP,LOWER_UP> 
nodelocaldns     DOWN           8a:60:49:67:a4:ac <BROADCAST,NOARP> 
calibb7b0422c3d@if2 UP             ee:ee:ee:ee:ee:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
calied8b574e736@if2 UP             ee:ee:ee:ee:ee:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
cali019a94320cf@if2 UP             ee:ee:ee:ee:ee:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
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
bond0: flags=5187<UP,BROADCAST,RUNNING,MASTER,MULTICAST>  mtu 9100
br-lag: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
cali019a94320cf: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
calibb7b0422c3d: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
calied8b574e736: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
en3f0pf0sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f0pf0sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f0pf0sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f1pf1sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f1pf1sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f1pf1sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
enp3s0f0s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f0s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
kube-ipvs0: flags=130<BROADCAST,NOARP>  mtu 1500
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
nodelocaldns: flags=130<BROADCAST,NOARP>  mtu 1500
oob_net0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
ovs-system: flags=4098<BROADCAST,MULTICAST>  mtu 1500
p0: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 9100
p1: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 9100
pf0hpf: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
pf0vf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
pf0vf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
pf0vf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
pf0vf3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
pf1hpf: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
pf1vf3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
tmfifo_net0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
vxlan.calico: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
hw-offload:
"true"
53346a65-f58e-4f8b-93c4-77ae4394e14f
    Bridge br-lag
        Port bond0
            Interface bond0
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port br-lag
            Interface br-lag
                type: internal
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port pf0hpf
            Interface pf0hpf
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
```

