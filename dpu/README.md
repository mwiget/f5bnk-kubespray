## Image and configure Nvidia Bluefield-3 DPU's

### Preparation

- ../.env populated with DPU_HOSTS, DPU_CLEAR_PASSWORD, MTU and EXTERNAL_VLAN
- sshpass binary installed locally
- Hosts listed in $DPU_HOSTS are reachable via ssh without password
- DPU nodes are derived from $DPU_HOSTS by adding '-dpu' and must be reachable via ssh
- check content of bf.conf.template

./generate-bf-conf.sh

Script uses the node list found in $DPU_HOSTS and generates individual DPU bf-<node-dpu>.conf files. 
Examine the generated bf-*.conf files for any obvious errors.

### Deployment

Now burn the DPU image with generated configuration file indvidually (use separate shells to track progress)

./deploy-bf-bundle.sh bf-<node>-dpu.conf

Script first downloads $BFB_IMAGE locally unless already present, then uploads it to the node (extracted name
from the provided config file) together with the bf-<node>-dpu.conf file, then remotely executes bfb-install via
ssh. Once complete, it waits until the dpu can be reached via its oob-net0 interface and finally pushes the ssh public
key to it for passwordless access (required by kubespray)

### Caveats

- VLAN host interfaces get removed during the DPU imaging process. Re-apply by running `sudo netplan apply` on the 
host. Script deploy-bf-bundle.sh does it automatically, but worth checking if all interfaces are present on the host.

