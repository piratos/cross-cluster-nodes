set -e
# Download and install cni plugin
wget https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz
sudo tar -xzvf "cni-plugins-linux-amd64-v0.8.6.tgz" --directory /opt/cni/bin/

# Config cni
# cluster 1
cat <<EOF | sudo tee /etc/c1/cni/net.d/10-weave.conf
{
    "name": "weave",
    "type": "weave-net",
    "hairpinMode": true,
    "plugins": [
        {
            "type": "bridge",
            "bridge": "cni0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "subnet": "10.244.0.0/24",
                "routes": [
                    { "dst": "0.0.0.0/0"   }
                ]
            }
        },
        {
            "type": "portmap",
            "capabilities": {"portMappings": true},
            "snat": true
        }
    ]
}
EOF
# cluster 2
cat <<EOF | sudo tee /etc/c2/cni/net.d/10-weave.conf
{
    "name": "weave",
    "type": "weave-net",
    "hairpinMode": true,
    "plugins": [
        {
            "type": "bridge",
            "bridge": "cni0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "subnet": "10.245.0.0/24",
                "routes": [
                    { "dst": "0.0.0.0/0"   }
                ]
            }
        },
        {
            "type": "portmap",
            "capabilities": {"portMappings": true},
            "snat": true
        }
    ]
}
EOF
