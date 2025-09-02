#!/bin/bash

# stop kubelet and reset kubeadm
sudo systemctl stop kubelet || true
sudo kubeadm reset -f

# drop stale containers/images (safe for OVS)
sudo crictl rm -a || true
sudo crictl rmi -a || true

# remove only kube + CNI state
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /etc/cni/net.d
