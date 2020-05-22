set -e
# Download and extract the binary
wget -q --show-progress --https-only --timestamping \
  "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"
{
  tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
  sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
}
# configure etcd for both clusters
# cluster 1
{
  sudo mkdir -p /etc/etcd1 /var/lib/etcd1
  sudo cp /srv/pkis/{ca.crt,etcd-server.key,etcd-server.crt} /etc/etcd1/
}
# cluster 2
{
  sudo mkdir -p /etc/etcd2 /var/lib/etcd2
  sudo cp /srv/pkis/{ca.crt,etcd-server.key,etcd-server.crt} /etc/etcd2/
}

# vars
INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
ETCD_NAME=$(hostname -s)

# Configure the etcd services
# cluster 1
cat <<EOF | sudo tee /etc/systemd/system/etcd1.service
[Unit]
Description=etcd1
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd1/etcd-server.crt \\
  --key-file=/etc/etcd1/etcd-server.key \\
  --peer-cert-file=/etc/etcd1/etcd-server.crt \\
  --peer-key-file=/etc/etcd1/etcd-server.key \\
  --trusted-ca-file=/etc/etcd1/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd1/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-1 \\
  --initial-cluster master=https://${INTERNAL_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# cluster 2
cat <<EOF | sudo tee /etc/systemd/system/etcd2.service
[Unit]
Description=etcd2
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd2/etcd-server.crt \\
  --key-file=/etc/etcd2/etcd-server.key \\
  --peer-cert-file=/etc/etcd2/etcd-server.crt \\
  --peer-key-file=/etc/etcd2/etcd-server.key \\
  --trusted-ca-file=/etc/etcd2/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd2/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2382 \\
  --listen-peer-urls https://${INTERNAL_IP}:2382 \\
  --listen-client-urls https://${INTERNAL_IP}:2381,https://127.0.0.1:2381 \\
  --advertise-client-urls https://${INTERNAL_IP}:2381 \\
  --initial-cluster-token etcd-cluster-2 \\
  --initial-cluster master=https://${INTERNAL_IP}:2382 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start etcd
# cluster 1
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd1
  sudo systemctl start etcd1
}
# cluster 2
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd2
  sudo systemctl start etcd2
}
