#!/bin/bash
#BFB_IMAGE="bf-bundle-2.9.2-32_25.02_ubuntu-22.04_prod.bfb"
BFB_IMAGE="bf-bundle-3.0.0-135_25.04_ubuntu-22.04_prod.bfb" 

if [ ! -e $BFB_IMAGE ]; then
  echo "downloading $BFB_IMAGE ..."
  wget -q --show-progress https://content.mellanox.com/BlueField/BFBs/Ubuntu22.04/$BFB_IMAGE
fi

BFB_CONFIG=bfb_config_dpu1.conf
echo "installing image using config $BFB_CONFIG ..."
sudo bfb-install --rshim rshim0 --config $BFB_CONFIG --bfb $BFB_IMAGE
ssh-keygen -f "/home/mwiget/.ssh/known_hosts" -R "192.168.100.2"
