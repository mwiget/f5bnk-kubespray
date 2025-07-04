Files and script used to generate DPU bf.cfg and image the Bluefield-3
using bfb-image tool.

Important: bf.conf contains mlxconfig command to enable LAG. If this hasn't 
been enabled already, a manual reboot of the bf3 is required.

bf.conf is an example bf.cfg file used while burning the OS on the dpu.

bf-firewall.conf is an extended version of bf.conf that includes ovs-ofctl firewall 
rules to limit incoming traffic on vlan 210 to 
ARP, IPv6ND, SSH, BGP, HTTP and HTTPS to protect the host 
from external traffic. Adjust as needed
