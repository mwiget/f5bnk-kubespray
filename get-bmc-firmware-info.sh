#!/bin/bash
source .env
BMCIP=$1
curl -k -u root:$BMC_SHARED_PASSWORD https://$BMCIP/redfish/v1/UpdateService/FirmwareInventory/BMC_Firmware
echo $?
