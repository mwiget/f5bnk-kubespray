#!/bin/bash

#BFB_IMAGE="bf-bundle-2.9.2-32_25.02_ubuntu-22.04_prod.bfb"
BFB_IMAGE="bf-bundle-3.0.0-135_25.04_ubuntu-22.04_prod.bfb" 

if [ ! -e $BFB_IMAGE ]; then
  echo "downloading $BFB_IMAGE ..."
  wget -q --show-progress https://content.mellanox.com/BlueField/BFBs/Ubuntu22.04/$BFB_IMAGE
fi
ls -l $BFB_IMAGE
