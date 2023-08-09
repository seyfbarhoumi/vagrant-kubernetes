#!/bin/bash

echo "---------- Install prerequisite on box $(hostname) ----------"

# Allow external ssh login on vbox
echo "[1]: Allow external ssh login on vbox on box $(hostname)"
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Configure /etc/hosts
echo "[2]: Configure /etc/hosts on box $(hostname)"
cat /vagrant_data/hosts >> /etc/hosts

# Disable swap
echo "[3]: Disable swap on box $(hostname)"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Set SELinux in permissive mode
echo "[4]: Set SELinux in permissive mode on box $(hostname)"
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Configure Firewall Rules
if systemctl is-active --quiet firewalld; then
    if [ "$hostname" = "master" ]; then
        echo "[5]: Configure Firewall Rules on box $(hostname)"
        sudo firewall-cmd --permanent --add-port=6443/tcp
        sudo firewall-cmd --permanent --add-port=2379-2380/tcp
        sudo firewall-cmd --permanent --add-port=10250/tcp
        sudo firewall-cmd --permanent --add-port=10251/tcp
        sudo firewall-cmd --permanent --add-port=10252/tcp
        sudo firewall-cmd --reload
        sudo modprobe br_netfilter
        sudo sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
        sudo sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"
    else
        echo "[5]: Configure Firewall Rules on box $(hostname)"
        sudo firewall-cmd --permanent --add-port=10250/tcp
        sudo firewall-cmd --permanent --add-port=30000-32767/tcp                                                  
        sudo firewall-cmd --reload
        sudo modprobe br_netfilter
        sudo sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
        sudo sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"
    fi
else
    echo "[5]: Skipping Configure Firewall Rules on box $(hostname)"
fi

# Install Docker
echo "[6]: Install Docker on box $(hostname)"
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce -y

# Configure Docker
echo "[7]: Configure Docker on box $(hostname)"
sudo usermod -aG docker vagrant
echo "alias docker='sudo docker'" >> ~/.bashrc
source ~/.bashrc

# Start Docker
echo "[8]: Start Docker on box $(hostname)"
sudo systemctl start docker
sudo systemctl enable docker

# Configure containerd
echo "[9]: Start Docker on box $(hostname)"
sudo sed -i 's/^disabled_plugins = \["cri"\]/# &/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Install kubelet, Kubeadm and kubectl
echo "[10]: Install kubelet, Kubeadm and kubectl on box $(hostname)"
# export VERSION="1.27.0-00"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
# sudo dnf install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION --disableexcludes=kubernetes
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Start Kubelet
echo "[11]: Start Kubelet on box $(hostname)"
sudo systemctl enable --now kubelet