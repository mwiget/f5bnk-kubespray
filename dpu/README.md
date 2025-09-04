## Image and configure Nvidia Bluefield-3 DPU's

- copy and adjust bf-firewall-jumbo.conf regarding MTU, ubuntu_password, VLAN
- copy your bf-firewall-jumbo.conf, console-dpu.sh and deploy-bf-bundle.sh to your worker node with the dpu
- on worker node, execute ./deploy-bf-bundle.sh bf-firewall-jumbo.conf
- from another shell on the worker node, monitor image progress with ./console-dpu.sh

### VLAN handling

The bf-firewall-jumbo.conf is static in nature and makes assumptions about MTU, VLAN (external and internal) 
and need to be adjusted:

- MTU is set to 9100
- External VLAN 210 has ovs firewall rules applied to protect from external/public
- VF's to the host are configured as access port with VLAN 200, allowing Pods to
attach via multus to VFs and be connected to internal VLAN 200 without specifying on the host.
- PF interface however passes all VLANs like a trunk port, allowing other VLANs be switched thru,
like storage. 


### Check DPU bond0, MTU and ovs-vsctl status

```
$ ./check-dpu.sh rome1-dpu

9c41be52-2299-46fb-9b74-caf1c33fc45a
    Bridge br-lag
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port pf0vf0
            tag: 200
            Interface pf0vf0
        Port pf0vf3
            tag: 200
            Interface pf0vf3
        Port pf0hpf
            Interface pf0hpf
        Port pf0vf2
            tag: 200
            Interface pf0vf2
        Port pf0vf1
            tag: 200
            Interface pf0vf1
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
        Port bond0
            Interface bond0
        Port br-lag
            Interface br-lag
                type: internal
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
oob_net0         UP             5c:25:73:e6:38:68 <BROADCAST,MULTICAST,UP,LOWER_UP> 
tmfifo_net0      UP             00:1a:ca:ff:ff:11 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p0               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
p1               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
pf0hpf           UP             aa:10:83:a4:1c:d4 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf0           UP             ae:a6:52:e3:3f:6e <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf1           UP             da:35:dd:f4:cf:87 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf2           UP             a2:79:e4:ac:40:52 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf3           UP             ca:6f:7d:fd:cb:82 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1hpf           UP             42:f1:98:e3:f9:4b <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf0           UP             c6:07:a9:38:c4:46 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf1           UP             d6:01:16:40:b3:93 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf2           UP             12:b2:9b:5d:da:cf <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf3           UP             36:97:ee:c5:fd:3c <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf0      UP             f6:45:0d:cb:10:c4 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s0       UP             02:8a:9e:67:68:a0 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf1      UP             8a:80:9d:ce:f2:13 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s1       UP             02:7a:b7:91:64:5a <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf2      UP             fe:14:43:18:eb:8c <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s2       UP             02:63:cd:26:c6:8b <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf0      UP             f6:56:a1:1b:7f:36 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s0       UP             02:26:9c:3e:68:9f <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf1      UP             86:32:aa:38:da:ca <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s1       UP             02:e8:4c:3f:e0:2d <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf2      UP             be:3f:22:43:df:7a <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s2       UP             02:d2:58:01:ac:5e <BROADCAST,MULTICAST,UP,LOWER_UP> 
bond0            UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
ovs-system       DOWN           12:3d:7b:d9:6d:ad <BROADCAST,MULTICAST> 
br-lag           UNKNOWN        5c:25:73:e6:38:54 <BROADCAST,MULTICAST,UP,LOWER_UP> 
kube-ipvs0       DOWN           2e:56:99:19:1d:19 <BROADCAST,NOARP> 
vxlan.calico     UNKNOWN        66:0e:38:7c:ea:f6 <BROADCAST,MULTICAST,UP,LOWER_UP> 
nodelocaldns     DOWN           c6:f1:69:af:1c:03 <BROADCAST,NOARP> 
calie4e74e04abc@if2 UP             ee:ee:ee:ee:ee:ee <BROADCAST,MULTICAST,UP,LOWER_UP> 
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
calie4e74e04abc: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f0pf0sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f0pf0sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f0pf0sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f1pf1sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f1pf1sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
en3f1pf1sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9100
enp3s0f0s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f0s1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f0s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
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

hw-offload:"true"

9c41be52-2299-46fb-9b74-caf1c33fc45a
    Bridge br-lag
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port pf0vf0
            tag: 200
            Interface pf0vf0
        Port pf0vf3
            tag: 200
            Interface pf0vf3
        Port pf0hpf
            Interface pf0hpf
        Port pf0vf2
            tag: 200
            Interface pf0vf2
        Port pf0vf1
            tag: 200
            Interface pf0vf1
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
        Port bond0
            Interface bond0
        Port br-lag
            Interface br-lag
                type: internal
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
```

