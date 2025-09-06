#!/usr/bin/env bash

set -e

DOCA_VERSION="2.9.2"

echo "installing ubuntu packages and DOCA networking $DOCA_VERSION ..."
export DOCA_URL="https://linux.mellanox.com/public/repo/doca/$DOCA_VERSION/ubuntu22.04/x86_64/"
curl https://linux.mellanox.com/public/repo/doca/GPG-KEY-Mellanox.pub \
  | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub >/dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/GPG-KEY-Mellanox.pub] $DOCA_URL ./" \
  | sudo tee /etc/apt/sources.list.d/doca.list >/dev/null

sudo apt-get update
sudo apt-get install -y curl ca-certificates make htop btop jq tmux mosh net-tools \
  bwm-ng tcpdump snapd python3-pip unzip ipmitool nfs-kernel-server golang-go \
  pv doca-networking wrk alsa-utils
sudo apt autoremove -y

sudo update-pciids

# use newer version of mosh
sudo add-apt-repository ppa:keithw/mosh-dev -y
sudo apt update
sudo apt list --upgradable
sudo apt upgrade mosh -y

echo ""
echo "installing mstflint to manage firmware"
sudo apt install mstflint -y
sudo systemctl enable --now mst

echo ""
echo "installing k9s ..."
VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -Lo k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${VERSION}/k9s_Linux_amd64.tar.gz"
tar -xzf k9s.tar.gz k9s
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz

echo ""
echo "installing helm & kubectl ..."
sudo snap install kubectl --classic
curl -sL https://get.helm.sh/helm-v3.17.3-linux-amd64.tar.gz | tar -xz --strip-components=1 linux-amd64/helm
sudo mv helm /usr/local/bin/

echo ""
echo "launching rshim ..."
sudo systemctl enable --now rshim
sudo systemctl status rshim

echo ""
echo "creating /etc/netplan/50-tmfifo.yaml to set static ip 192.168.100.1/30 on tmfifo_net0 ..."
sudo tee /etc/netplan/50-tmfifo.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    tmfifo_net0:
      dhcp4: no
      addresses:
        - 192.168.100.1/30
EOF
sudo chmod 600 /etc/netplan/50-tmfifo.yaml
sudo netplan apply

echo ""
ip -br a

echo ""
echo "Installing NVIDIA GPU drivers ..."
# 1. Add the official graphics drivers PPA
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt update
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall

echo ""
echo "please reboot for GPU drivers to run."
