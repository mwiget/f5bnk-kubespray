## Image and configure Nvidia Bluefield-3 DPU's

- copy and adjust bf-firewall-jumbo.conf regarding MTU, ubuntu_password, VLAN
- copy your bf-firewall-jumbo.conf, console-dpu.sh and deploy-bf-bundle.sh to your worker node with the dpu
- on worker node, execute ./deploy-bf-bundle.sh bf-firewall-jumbo.conf
- from another shell on the worker node, monitor image progress with ./console-dpu.sh


### Caveats

- VLAN host interfaces get removed during the DPU imaging process. Re-apply by running `sudo netplan apply` on the 
host. Script deploy-bf-bundle.sh does it automatically, but worth checking if all interfaces are present on the host.
