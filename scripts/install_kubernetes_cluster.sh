#!/bin/bash

echo "---------- Install kuberntes cluster on box $(hostname) ----------"

# Initialize the cluster with kubeadm
echo "[1]: Initialize the cluster with kubeadm on box $(hostname)"
sudo kubeadm init --v=5 \
--upload-certs \
--control-plane-endpoint master:6443 \
--pod-network-cidr=10.244.0.0/16 \
--ignore-preflight-errors=NumCPU

# Configure kubectl
echo "[2]: Start Kubelet on box $(hostname)"
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
sudo dnf -y install bash-completion
echo "alias k=kubectl" >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

# source <(kubectl completion bash) && \
# echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc && \
# complete -o default -F __start_kubectl k

# Get the worker nodes join command
echo "[3]: Get the worker nodes join command"
kubeadm token create --print-join-command


