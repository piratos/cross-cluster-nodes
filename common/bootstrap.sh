#!/bin/bash

# Update hosts file
echo "[TASK] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.2.2 master.example.com master
192.168.2.3 worker.example.com worker
EOF

# Download kubectl
wget -q --show-progress --https-only --timestamping \
    "https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Add sysctl settings
echo "[TASK] Add sysctl settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1

# Disable swap
echo "[TASK] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

# Enable ssh password authentication
echo "[TASK] Enable ssh password authentication"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Set Root password
echo "[TASK] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root
#echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc

# Create setup folders
mkdir /srv/{pkis,kubeconfigs,manifests}
