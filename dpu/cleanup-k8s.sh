#!/bin/bash

# stop kubelet and reset kubeadm
sudo systemctl stop containerd kubelet kubepods.slice || true
sudo kubeadm reset -f

# drop stale containers/images (safe for OVS)
sudo crictl rm -a || true
sudo crictl rmi -a || true

# remove only kube + CNI state
sudo rm -rf /var/lib/containerd/* /run/containerd/* /etc/kubernetes /var/lib/kubelet /var/lib/etcd /etc/cni/net.d
sudo systemctl daemon-reload
