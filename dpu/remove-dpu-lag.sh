#!/bin/bash
set -e
DPU=rome1-dpu
ssh $DPU "sudo mlxconfig -d /dev/mst/mt41692_pciconf0 -y s HIDE_PORT2_PF=False NUM_OF_PF=2"
ssh $DPU "sudo mlxconfig -d /dev/mst/mt41692_pciconf0 -y s LAG_RESOURCE_ALLOCATION=DEVICE_DEFAULT"
