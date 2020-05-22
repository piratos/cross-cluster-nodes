set -e

# Create config dir
sudo mkdir -p /etc/kubernetes1/config
sudo mkdir -p /etc/kubernetes2/config

# Download binaries
[ -f /usr/local/bin/kube-apiserver ] || wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kube-scheduler"

# chmod
{
  [ -f /usr/local/bin/kube-apiserver ] || chmod +x kube-apiserver kube-controller-manager kube-scheduler
  [ -f /usr/local/bin/kube-apiserver ] || sudo mv kube-apiserver kube-controller-manager kube-scheduler /usr/local/bin/
}

# configure kube apiserver
# cluster 1
{
  sudo mkdir -p /var/lib/kubernetes1/

  sudo cp /srv/pkis/ca.crt /srv/pkis/ca.key /srv/pkis/kube-apiserver1.crt \
    /srv/pkis/kube-apiserver.key /srv/pkis/service-account.key /srv/pkis/service-account.crt \
    /srv/pkis/etcd-server.key /srv/pkis/etcd-server.crt \
    /srv/manifests/encryption-config.yaml /var/lib/kubernetes1/
}
# cluster 2
{
  sudo mkdir -p /var/lib/kubernetes2/

  sudo cp /srv/pkis/ca.crt /srv/pkis/ca.key /srv/pkis/kube-apiserver2.crt \
    /srv/pkis/kube-apiserver.key /srv/pkis/service-account.key /srv/pkis/service-account.crt \
    /srv/pkis/etcd-server.key /srv/pkis/etcd-server.crt \
    /srv/manifests/encryption-config.yaml /var/lib/kubernetes2/
}

# vars
INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)

# Create service files for kube apiserver
# cluster 1
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver1.service
[Unit]
Description=Kubernetes API Server 1
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit1.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --insecure-port=8080 \\
  --secure-port=6443 \\
  --client-ca-file=/var/lib/kubernetes1/ca.crt \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-bootstrap-token-auth=true \\
  --etcd-cafile=/var/lib/kubernetes1/ca.crt \\
  --etcd-certfile=/var/lib/kubernetes1/etcd-server.crt \\
  --etcd-keyfile=/var/lib/kubernetes1/etcd-server.key \\
  --etcd-servers=https://${INTERNAL_IP}:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes1/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes1/ca.crt \\
  --kubelet-client-certificate=/var/lib/kubernetes1/kube-apiserver1.crt \\
  --kubelet-client-key=/var/lib/kubernetes1/kube-apiserver.key \\
  --kubelet-https=true \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes1/service-account.crt \\
  --service-cluster-ip-range=10.96.0.0/24 \\
  --service-node-port-range=30000-31383 \\
  --tls-cert-file=/var/lib/kubernetes1/kube-apiserver1.crt \\
  --tls-private-key-file=/var/lib/kubernetes1/kube-apiserver.key \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# cluster 2

cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver2.service
[Unit]
Description=Kubernetes API Server 2
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit2.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --insecure-port=8081 \\
  --secure-port=6444 \\
  --client-ca-file=/var/lib/kubernetes2/ca.crt \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-bootstrap-token-auth=true \\
  --etcd-cafile=/var/lib/kubernetes2/ca.crt \\
  --etcd-certfile=/var/lib/kubernetes2/etcd-server.crt \\
  --etcd-keyfile=/var/lib/kubernetes2/etcd-server.key \\
  --etcd-servers=https://${INTERNAL_IP}:2381 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes2/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes2/ca.crt \\
  --kubelet-client-certificate=/var/lib/kubernetes2/kube-apiserver2.crt \\
  --kubelet-client-key=/var/lib/kubernetes2/kube-apiserver.key \\
  --kubelet-https=true \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes2/service-account.crt \\
  --service-cluster-ip-range=10.97.0.0/24 \\
  --service-node-port-range=31384-32767 \\
  --tls-cert-file=/var/lib/kubernetes2/kube-apiserver2.crt \\
  --tls-private-key-file=/var/lib/kubernetes2/kube-apiserver.key \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure kube controller manager service
# cluster 1
sudo cp /srv/kubeconfigs/kube-controller-manager1.kubeconfig /var/lib/kubernetes1/

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager1.service
[Unit]
Description=Kubernetes Controller Manager 1
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --secure-port=0 \\
  --port=10252 \\
  --cluster-cidr=192.168.2.0/24 \\
  --cluster-name=kubernetes1 \\
  --cluster-signing-cert-file=/var/lib/kubernetes1/ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes1/ca.key \\
  --kubeconfig=/var/lib/kubernetes1/kube-controller-manager1.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes1/ca.crt \\
  --service-account-private-key-file=/var/lib/kubernetes1/service-account.key \\
  --service-cluster-ip-range=10.96.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
# cluster 2
sudo cp /srv/kubeconfigs/kube-controller-manager2.kubeconfig /var/lib/kubernetes2/

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager2.service
[Unit]
Description=Kubernetes Controller Manager 2
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --secure-port=0 \\
  --port=10262 \\
  --cluster-cidr=192.168.2.0/24 \\
  --cluster-name=kubernetes2 \\
  --cluster-signing-cert-file=/var/lib/kubernetes2/ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes2/ca.key \\
  --kubeconfig=/var/lib/kubernetes2/kube-controller-manager2.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes2/ca.crt \\
  --service-account-private-key-file=/var/lib/kubernetes2/service-account.key \\
  --service-cluster-ip-range=10.97.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure kube scheduler
# cluster 1
sudo cp /srv/kubeconfigs/kube-scheduler1.kubeconfig /var/lib/kubernetes1/
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler1.service
[Unit]
Description=Kubernetes Scheduler 1
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --kubeconfig=/var/lib/kubernetes1/kube-scheduler1.kubeconfig \\
  --address=127.0.0.1 \\
  --secure-port=0 \\
  --port=10251 \\
  --leader-elect=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
# cluster 2
sudo cp /srv/kubeconfigs/kube-scheduler2.kubeconfig /var/lib/kubernetes2/
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler2.service
[Unit]
Description=Kubernetes Scheduler 2
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --kubeconfig=/var/lib/kubernetes2/kube-scheduler2.kubeconfig \\
  --address=127.0.0.1 \\
  --secure-port=0 \\
  --port=10261 \\
  --leader-elect=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start the controllers
# cluster 1
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver1 kube-controller-manager1 kube-scheduler1
  sudo systemctl start kube-apiserver1 kube-controller-manager1 kube-scheduler1
}
# cluster 2
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver2 kube-controller-manager2 kube-scheduler2
  sudo systemctl start kube-apiserver2 kube-controller-manager2 kube-scheduler2
}

