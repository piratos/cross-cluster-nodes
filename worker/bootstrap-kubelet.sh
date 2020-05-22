set -e

# Download binaries
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubelet

# Create needed directories
sudo mkdir -p \
  /etc/cni/net1.d \
  /etc/cni/net2.d \
  /opt/cni/bin \
  /var/lib/kubelet1 \
  /var/lib/kubelet2 \
  /var/lib/kube-proxy1 \
  /var/lib/kube-proxy2 \
  /var/lib/kubernetes1 \
  /var/lib/kubernetes2 \
  /var/run/kubernetes1 \
  /var/run/kubernetes2

# Install binaries
{
  chmod +x kube-proxy kubelet
  sudo mv kube-proxy kubelet /usr/local/bin/
}
exit
# Move the cert key and kubeconfig
{
  sudo cp worker.key worker.crt /var/lib/kubelet1/
  sudo mv worker.key worker.crt /var/lib/kubelet2/
  sudo mv worker-c1.kubeconfig /var/lib/kubelet1/kubeconfig
  sudo mv worker-c2.kubeconfig /var/lib/kubelet2/kubeconfig
  sudo cp ca.crt /var/lib/kubernetes1/
  sudo mv ca.crt /var/lib/kubernetes2/
}

# Generate kubelet config
# cluster 1
cat <<EOF | sudo tee /var/lib/kubelet1/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 0.0.0.0
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes1/ca.crt"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.96.0.10"
healthzPort: 10248
port: 10250
readOnlyPort: 10255
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
EOF
# cluster 2
cat <<EOF | sudo tee /var/lib/kubelet2/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 0.0.0.0
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes2/ca.crt"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.97.0.10"
healthzPort: 10258
port: 10260
readOnlyPort: 10265
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
EOF

# Configure kubelet OS service
# cluster 1
cat <<EOF | sudo tee /etc/systemd/system/kubelet1.service
[Unit]
Description=Kubernetes Kubelet 1
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet1/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet1/kubeconfig \\
  --tls-cert-file=/var/lib/kubelet1/worker.crt \\
  --tls-private-key-file=/var/lib/kubelet1/worker.key \\
  --network-plugin=cni \\
  --cni-conf-dir=/etc/cni/net1.d \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
# cluster 2
cat <<EOF | sudo tee /etc/systemd/system/kubelet2.service
[Unit]
Description=Kubernetes Kubelet 2
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet2/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet2/kubeconfig \\
  --tls-cert-file=/var/lib/kubelet2/worker.crt \\
  --tls-private-key-file=/var/lib/kubelet2/worker.key \\
  --network-plugin=cni \\
  --cni-conf-dir=/etc/cni/net2.d \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Move kube-proxy conf
#sudo mv kube-proxy1.kubeconfig /var/lib/kube-proxy1/kubeconfig
#sudo mv kube-proxy2.kubeconfig /var/lib/kube-proxy2/kubeconfig

# Generate kube-proxy conf
# cluster 1
cat <<EOF | sudo tee /var/lib/kube-proxy1/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy1/kubeconfig"
healthzBindAddress: 0.0.0.0:10268
metricsBindAddress: 127.0.0.1:10269
mode: "iptables"
clusterCIDR: "192.168.2.0/24"
EOF
# cluster 2
cat <<EOF | sudo tee /var/lib/kube-proxy2/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy2/kubeconfig"
healthzBindAddress: 0.0.0.0:10270
metricsBindAddress: 127.0.0.1:10271
mode: "iptables"
clusterCIDR: "192.168.2.0/24"
EOF

# Create kube proxy service files
# cluster 1
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy1.service
[Unit]
Description=Kubernetes Kube Proxy 1
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy1/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
# cluster 2
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy2.service
[Unit]
Description=Kubernetes Kube Proxy 2
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy2/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start the services
# cluster 1
{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet1 kube-proxy1
  sudo systemctl start kubelet1 kube-proxy1
}
# cluster 2
{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet2 kube-proxy2
  sudo systemctl start kubelet2 kube-proxy2
}

