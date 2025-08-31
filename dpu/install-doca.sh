#!/bin/bash

export DOCA_URL="https://linux.mellanox.com/public/repo/doca/2.9.2/ubuntu22.04/x86_64/"
#export DOCA_URL="https://linux.mellanox.com/public/repo/doca/3.1.0/ubuntu22.04/x86_64/"
BASE_URL=$([ "${DOCA_PREPUBLISH:-false}" = "true" ] && echo https://doca-repo-prod.nvidia.com/public/repo/doca || echo https://linux.mellanox.com/public/repo/doca)
DOCA_SUFFIX=${DOCA_URL#*public/repo/doca/}; DOCA_URL="$BASE_URL/$DOCA_SUFFIX"
curl $BASE_URL/GPG-KEY-Mellanox.pub | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub >/dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub] $DOCA_URL ./" | sudo tee  /etc/apt/sources.list.d/doca.list
sudo apt-get update
sudo apt-get -y install doca-all
