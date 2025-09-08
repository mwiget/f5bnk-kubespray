# f5bnk-kubespray

Deploy F5 BNK https://clouddocs.f5.com/bigip-next-for-kubernetes/latest/
on baremetal nodes
with Nvidia Bluefield-3 using kubespray, connected via LAG to the DC Fabric.

![Dual node lab setup](./two-node-lab-setup.jpg)

## Requirements

- f5-far-auth-key.tgz (download from myf5.com, place the tgz file in ~/far/ folder)
- JWT Token placed in file ~/.jwt
- docker or podman
- kubectl, helm, yq
- baremetal server with Nvidia Bluefield-3
- Ethernet switch with LAG LACP support. Switch redundancy (p0 and p1 connected to different leaf/ToR switches) requires
MC-LAG or EVPN-MH.
- Prepare DPUs. See [./dpu](./dpu)
- NFS server, referenced in resources/storageclass.yaml. Adjust accordingly. Example NFS /etc/exports with required flags

```
/share/bnk  *(rw,sync,no_subtree_check,no_root_squash)
```

## Deployment

1. Prepare compute nodes with Ubuntu OS, enable SR-IOV and Virtual Functions. Example netplan configs in [./netplan](./netplan). Storage and External VLAN require tagged interfaces on the nodes, while the internal VLAN tag will be removed by the DPU: the DPU treats the internal VLAN over the Virtual Function as access port.

2. Prepare DPUs. See [./dpu](./dpu)

3. Deploy cluster and BNK

Makefile defines the various deployment steps, starging with kubespray (using docker or podman) to deploy dual node 
cluster, defined in [./inventory/dual-node/inventory.yaml](./inventory/dual-node/inventory.yaml]. Adjust the number of
nodes as needed in that file. Check [./Makefile](./Makefile) to break down deployment steps, e.g. to first deploy
just the cluster (`make cluster`), followed by (`make extras`) to add cert-manager, grafana and nvidia-gpu-operator and
finally (`make bnk`) to deploy BNK and BNK Gateway Class. 

Before running `make`, create .env by copying [./env.example](./env.example) to .env and adjust variables to match
your setup.

Deploy cluster and bnk by launching `make all`. 

```
make all
. . .
waiting for all f5-spk-vlans configured ...
NAME       READY   MESSAGE   AGE
external                     3m7s
internal                     3m7s
storage                      3m7s
waiting for all f5-spk-vlans configured ...
NAME       READY   MESSAGE   AGE
external                     3m12s
internal                     3m12s
storage                      3m12s
waiting for all f5-spk-vlans configured ...
NAME       READY   MESSAGE                               AGE
external   False   CR config deployment is in progress   3m17s
internal   False   CR config deployment is in progress   3m17s
storage    False   CR config deployment is in progress   3m17s
NAME       READY   MESSAGE                                AGE
external   True    CR config sent to all grpc endpoints   3m23s
internal   True    CR config sent to all grpc endpoints   3m23s
storage    True    CR config sent to all grpc endpoints   3m23s
```

The message about waiting for all f5-spk-vlans can take up to 5 minutes to clear until `CR config sent to all
grpc endpoints` is shown. Pods take time to deploy. Monitor progress with `kubectl get pods -A` or use k9s.

If no message is shown even after 5 minutes, something might be wrong with the provided license token (JWT).

Successful license CWC log entry:

```
$ kubectl -n f5-utils get pod |grep cwc
f5-spk-cwc-fbf65b9d6-p5vgm          2/2     Running     0          12m

$ kubectl -n f5-utils logs f5-spk-cwc-fbf65b9d6-p5vgm | grep LicenseVerified
Defaulted container "f5-spk-cwc" out of: f5-spk-cwc, f5-csm-qkview
"ts"="2025-09-08 10:26:18.452"|"l"="info"|"m"="Publishing event message to SPK Controllers"|"lt"="S"|"id"="18030-000312"|"event"="EventCM20LicenseVerified"|"entitlement"="paid"|"expiry"="2026-08-31T01:01:55Z"|"uuid"="c1fe89f2-4366-46d6-9b3b-62515a556dbf"|"ct"="spkcwc"|"v"="1.0"
"ts"="2025-09-08 10:26:19.678"|"l"="info"|"m"="Creating CM20 Response"|"lt"="S"|"id"="18030-000300"|"responsetype"="ResponseCM20LicenseVerified"|"entitlement"="paid"|"expiry"="2026-08-31T01:01:55Z"|"uuid"="c1fe89f2-4366-46d6-9b3b-62515a556dbf"|"signKeyVer"="2025-09-08T10:25:24Z"|"ct"="spkcwc"|"v"="1.0"
```

TMM pods are default in default namespace:

```
$ kubectl get pod -o wide

NAME                                            READY   STATUS      RESTARTS   AGE   IP              NODE         NOMINATED NODE   READINESS GATES
f5-afm-6cb47fd657-wpqzm                         1/1     Running     0          14m   10.233.74.156   milan1       <none>           <none>
f5-bnk-env-discovery-job-dpu-milan1-dpu-mclng   0/1     Completed   0          59s   192.168.68.96   milan1-dpu   <none>           <none>
f5-bnk-env-discovery-job-dpu-rome1-dpu-qm9b5    0/1     Completed   0          51s   192.168.68.79   rome1-dpu    <none>           <none>
f5-bnk-env-discovery-job-host-milan1-vzvjt      0/1     Completed   0          41s   192.168.68.73   milan1       <none>           <none>
f5-bnk-env-discovery-job-host-rome1-rp2t6       0/1     Completed   0          28s   192.168.68.62   rome1        <none>           <none>
f5-cne-controller-6fcd5cb8f8-dqvpv              3/3     Running     0          14m   10.233.86.20    rome1        <none>           <none>
f5-observer-0                                   1/1     Running     0          14m   10.233.74.155   milan1       <none>           <none>
f5-observer-operator-5b9856fb49-hfgmf           1/1     Running     0          14m   10.233.74.154   milan1       <none>           <none>
f5-observer-receiver-0                          1/1     Running     0          14m   10.233.74.157   milan1       <none>           <none>
f5-tmm-lqxp8                                    6/6     Running     0          14m   10.233.119.4    rome1-dpu    <none>           <none>
f5-tmm-qxkxb                                    6/6     Running     0          14m   10.233.89.196   milan1-dpu   <none>           <none>
otel-collector-7fc76cf9b6-lwz98                 1/1     Running     0          14m   10.233.74.159   milan1       <none>           <none>
```

To explore use cases, check out [./labs](./labs). 


## Destroy setup

```
make clean-all
```

Uses kubespray to destroy the cluster. To re-deploy, re-imaging DPU's is required, because kubespray removes OVS, despite being asked not to touch OVS 
during deployment.


### Caveats

- VLAN host interfaces get removed during the DPU imaging process. Re-apply by running `sudo netplan apply` on the 
host. Script deploy-bf-bundle.sh does it automatically, but worth checking if all interfaces are present on the host.
- High speed interfaces (from DPU) on worker nodes must have provisioned VF's on both physical ports. FLO checks those
prior to deploying into namespace f5-utils

## Resources

- https://clouddocs.f5.com/bigip-next-for-kubernetes/latest/
- https://github.com/kubernetes-sigs/kubespray (source of sample inventory)
- https://github.com/f5devcentral/f5-bnk-nvidia-bf3-installations (for non-LAG deployment)
- https://docs.nvidia.com/networking/display/bluefielddpuosv460/link+aggregation
