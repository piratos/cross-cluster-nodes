#!/bin/bash

echo "[TASK] Install docker container engine"
apt-get install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install docker-ce -y

# add ccount to the docker group
usermod -aG docker vagrant

# Disable service
echo "[TASK] Disable, mask and stop docker service"
systemctl disable docker >/dev/null 2>&1
systemctl mask docker >/dev/null 2>&1
systemctl stop docker

# Create users for the docker namespace
id -u cluster1 || sudo useradd -m -s /bin/bash cluster1
id -u cluster2 || sudo useradd -m -s /bin/bash cluster2

# Create dirs
mkdir -p /var/run/docker1 /var/lib/docker1
mkdir -p /var/run/docker2 /var/lib/docker2

cat <<EOF | tee /etc/systemd/system/docker-cluster1.socket
[Unit]
Description=Docker Socket for the API
PartOf=docker-cluster1.service

[Socket]
ListenStream=/var/run/docker-cluster1.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

cat <<EOF | tee /etc/systemd/system/docker-cluster2.socket
[Unit]
Description=Docker Socket for the API
PartOf=docker-cluster2.service

[Socket]
ListenStream=/var/run/docker-cluster2.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF



cat <<EOF | tee /etc/systemd/system/docker-cluster1.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
BindsTo=containerd.service
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker-cluster1.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd \\
          --containerd /run/containerd/containerd.sock \\
          --exec-opt native.cgroupdriver=systemd \\
          --host unix:///var/run/docker-cluster1.sock \\
          --userns-remap cluster1 \\
          --bridge cluster1 \\
          --data-root /var/lib/docker1 \\
          --exec-root /var/run/docker1 \\
          --pidfile /var/run/docker-cluster1.pid
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
TasksMax=8192
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | tee /etc/systemd/system/docker-cluster2.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
BindsTo=containerd.service
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker-cluster2.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd \\
          --containerd /run/containerd/containerd.sock \\
          --exec-opt native.cgroupdriver=systemd \\
          --host unix:///var/run/docker-cluster2.sock \\
          --userns-remap cluster2 \\
          --bridge cluster2 \\
          --data-root /var/lib/docker2 \\
          --exec-root /var/run/docker2 \\
          --pidfile /var/run/docker-cluster2.pid
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
TasksMax=8192
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF


# Enable and start docker
systemctl daemon-reload
# cluster 1
systemctl enable docker-cluster1.socket docker-cluster1.service
systemctl start docker-cluster1.socket docker-cluster1.service
# cluster 2
systemctl enable docker-cluster2.socket docker-cluster2.service
systemctl start docker-cluster2.socket docker-cluster2.service
