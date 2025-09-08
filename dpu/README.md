# Link Aggregation via Nvidia Bluefield-3 DPU

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

- Ethernet switch configured for Link Aggregation (LAG) for the Bluefield-3 ports p0 and p1. If connected to different
leaf/ToR switches, MC-LAG or EVPN-MH is required on the switches. LACP must be set to fast (1second interval).
- DOCA 2.9.2 installed on hosts with DPUs with running rshim service and bfb-install utility.
- DPU OOB Ethernet ports connected to the same network as the worker nodes mgmt interface (NodeIPs)
- Nvidia Bluefield-3 bf-bundle-2.9.2 bfb image. Use [./download-bf-bundle.sh](./download-bf-bundle.sh) to download
the image from Nvidia or use their official download side.
- Create bf.conf DPU configuration for each Bluefield-3 DPU. Use one of the example templates as starting point: 
[./bf-jumbo.conf](./bf-jumbo.conf) or [./bf-firewall-jumbo.conf](./bf-firewall-jumbo.conf), which adds ovs firewall
rules to protect external traffic coming into the DPU over the high speed interfaces on a given VLAN. Adjust hostname, 
encrypted password for ubuntu user (use `openssl passwd -1 "<clear_password>"), 
external VLAN (which is used to pop the vlan tag before sending to the host and added on egress). The MTU is set to 9000, 
which is the maximum TMM supports. Adjust as needed, ensuring it is set to the same value on host and the connecting 
switch.
- Check Virtual Function on the host to match the VF representors in OVS_BRIDGE1_PORTS in bf.conf. The templates assume
4 VFs on the host on the first PF. Example netplan configs can be found in [../netplan](../netplan). The DPU will fail
to populate ovs bridge br-lag if VFs are missing on the host.

## Deployment

Copy bfb image and bf.conf file to the host with DPU, then start imaging process with

```
sudo bfb-install --rshim rshim0 --config bf.conf --bfb bf-bundle-2.9.2-32_25.02_ubuntu-22.04_prod.bfb`
```

or use the script [./deploy-bf-bundle.sh](./deploy-bf-bundle.sh). This will take several minutes and reboot the DPU
automatically. You can follow progress (during and after bfb-install finished) from another terminal using 
[./console-dpu.sh](./console-dpu.sh)

Once DPU OOB IP address is reachable, make sure you can ssh into it as user ubuntu without password. This is required
for creating the k8s cluster using kubespray. 


## Image and configure Nvidia Bluefield-3 DPU's

- copy and adjust bf-firewall-jumbo.conf regarding MTU, ubuntu_password, VLAN
- copy your bf-firewall-jumbo.conf, console-dpu.sh and deploy-bf-bundle.sh to your whe  tag 210 pop> enp193s0f0np0f0v0
- on worker node, execute ./deploy-bf-bundle.sh bf-firewall-jumbo.conf
- from another shell on the wf0orker node, monitor image progress with ./console-dpu.sh
- Wait for all DPU's reachable via oob_net0 interfaces
- Allow password-less ssh access to DPU (e.g. using ssh-copy-id)
- Re-apply `netplan` on the hosts with DPUs, as DPU VF and VLAN interfaces can disappear during imaging process

### Caveats

- DPU reboot will require re-applying `netplan` on the host, because the Virtual Functions (VF) disappear during the
process


### Check DPU bond0, MTU and ovs-vsctl status

You can use the provided script [./check-dpu.sh](./check-dpu.sh) to veriy proper ovs bridge population, interface and
LAG status as well as MTU settings.

```
$ ./check-dpu.sh rome1-dpu

94847133-e3c4-40d6-90d5-01c9637d5502
    Bridge br-lag
        Port pf0vf0
            tag: 200
            Interface pf0vf0
        Port pf0vf3
            tag: 200
            Interface pf0vf3
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port pf0vf1
            tag: 200
            Interface pf0vf1
        Port pf0hpf
            Interface pf0hpf
        Port br-lag
            Interface br-lag
                type: internal
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
        Port pf0vf2
            tag: 200
            Interface pf0vf2
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
        Port bond0
            Interface bond0
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
oob_net0         UP             5c:25:73:e6:38:68 <BROADCAST,MULTICAST,UP,LOWER_UP> 
tmfifo_net0      UP             00:1a:ca:ff:ff:11 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p0               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
p1               UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
ovs-system       DOWN           46:b6:2a:1c:0f:47 <BROADCAST,MULTICAST> 
br-lag           DOWN           5c:25:73:e6:38:54 <BROADCAST,MULTICAST> 
pf0hpf           UP             da:78:ee:ab:36:ac <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1hpf           UP             d6:8f:76:c5:4a:9e <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf0      UP             2a:9f:06:de:c8:ea <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s0       UP             02:2a:0f:b9:67:d2 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf1      UP             52:6f:da:ec:9a:22 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s1       UP             02:42:7f:f6:bc:36 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f0pf0sf2      UP             4a:d7:e3:95:de:09 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f0s2       UP             02:fb:b9:54:f3:4d <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf0      UP             ee:d3:42:53:48:9e <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s0       UP             02:20:e9:9b:7a:79 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf1      UP             5a:96:11:96:19:e6 <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s1       UP             02:36:06:8c:ce:c1 <BROADCAST,MULTICAST,UP,LOWER_UP> 
en3f1pf1sf2      UP             e6:dd:eb:10:b4:0b <BROADCAST,MULTICAST,UP,LOWER_UP> 
enp3s0f1s2       UP             02:6a:44:af:bf:7a <BROADCAST,MULTICAST,UP,LOWER_UP> 
bond0            UP             5c:25:73:e6:38:54 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
pf0vf0           UP             ba:ff:69:b8:85:90 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf1           UP             b6:b0:a3:e8:5d:b0 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf2           UP             3a:8f:63:56:ea:26 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf0vf3           UP             ee:43:53:ee:74:c4 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf0           UP             0e:b8:d2:7a:3c:de <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf1           UP             7a:99:ed:4c:62:cc <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf2           UP             66:03:bd:f8:c6:f1 <BROADCAST,MULTICAST,UP,LOWER_UP> 
pf1vf3           UP             82:27:45:78:08:b7 <BROADCAST,MULTICAST,UP,LOWER_UP> 
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
br-lag: flags=4098<BROADCAST,MULTICAST>  mtu 9000
en3f0pf0sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f0pf0sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f0pf0sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f1pf1sf0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f1pf1sf1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
en3f1pf1sf2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
enp3s0f0s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f0s1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f0s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
enp3s0f1s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
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

hw-offload:"true"

94847133-e3c4-40d6-90d5-01c9637d5502
    Bridge br-lag
        Port pf0vf0
            tag: 200
            Interface pf0vf0
        Port pf0vf3
            tag: 200
            Interface pf0vf3
        Port en3f0pf0sf0
            Interface en3f0pf0sf0
        Port pf0vf1
            tag: 200
            Interface pf0vf1
        Port pf0hpf
            Interface pf0hpf
        Port br-lag
            Interface br-lag
                type: internal
        Port en3f1pf1sf1
            Interface en3f1pf1sf1
        Port pf0vf2
            tag: 200
            Interface pf0vf2
        Port en3f1pf1sf0
            Interface en3f1pf1sf0
        Port en3f0pf0sf1
            Interface en3f0pf0sf1
        Port bond0
            Interface bond0
        Port en3f0pf0sf2
            Interface en3f0pf0sf2
        Port en3f1pf1sf2
            Interface en3f1pf1sf2
    ovs_version: "2.9.2-0011-25.02-based-3.3.3"
```
