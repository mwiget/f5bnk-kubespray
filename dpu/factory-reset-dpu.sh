#!/bin/bash
source ../.env
BMC_USER=root
BMC_IP=$1
set -e

if [ -z "$BMC_IP" ]; then
    echo "Usage: $0 <BMC_IP>" >&2
      exit 1
fi

echo "eMMC wipe ..."
curl -sk -u $BMC_USER:"$BMC_SHARED_PASSWORD" -X PATCH \
  -H "Content-Type: application/json" \
  -d '{"Attributes":{"EmmcWipe": true}}' \
  https://$BMC_IP/redfish/v1/Systems/Bluefield/Bios/Settings

echo "NVMe wipe ..."
curl -sk -u $BMC_USER:"$BMC_SHARED_PASSWORD" -X PATCH \
  -H "Content-Type: application/json" \
  -d '{"Attributes":{"NvmeWipe": true}}' \
  https://$BMC_IP/redfish/v1/Systems/Bluefield/Bios/Settings

echo "reset UEFI variables ..."
curl -sk -u $BMC_USER:"$BMC_SHARED_PASSWORD" -X PATCH \
  -H "Content-Type: application/json" \
  -d '{"Attributes":{"ResetEfiVars": true}}' \
  https://$BMC_IP/redfish/v1/Systems/Bluefield/Bios/Settings

ssh $BMC_IP "mlxconfig -d /dev/mst/mt41692_pciconf0 -y reset"

echo "Sending ResetAll to DPU BMC $BMC_IP ..."

#curl -sk -u $BMC_USER:"$BMC_SHARED_PASSWORD" \
#  -H "Content-Type: application/json" \
#  -X POST \
#  -d '{"ResetToDefaultsType":"ResetAll"}' \
#  https://$BMC_IP/redfish/v1/Managers/Bluefield_BMC/Actions/Manager.ResetToDefaults

echo "Trigger DPU BMC restart ..."

#curl -sk -u $BMC_USER:"$BMC_SHARED_PASSWORD" \
#  -H "Content-Type: application/json" \
#  -X POST \
#  -d '{"ResetType":"GracefulRestart"}' \
#  https://$BMC_IP/redfish/v1/Managers/Bluefield_BMC/Actions/Manager.Reset
