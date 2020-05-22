set -e

# Move to the pkis dir
cd /srv/pkis

# Generate the worker certificate
cat > openssl-worker.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = worker
IP.1 = 192.168.2.3
EOF

openssl genrsa -out worker.key 2048
openssl req -new -key worker.key -subj "/CN=system:node:worker/O=system:nodes" -out worker.csr -config openssl-worker.cnf
openssl x509 -req -in worker.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out worker.crt -extensions v3_req -extfile openssl-worker.cnf -days 1000

# Generate the worker kubeconfig
# cluster 1
{
  kubectl config set-cluster cluster1  \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://192.168.2.2:6443 \
    --kubeconfig=/srv/kubeconfigs/worker-c1.kubeconfig

  kubectl config set-credentials system:node:worker \
    --client-certificate=/srv/pkis/worker.crt \
    --client-key=/srv/pkis/worker.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/worker-c1.kubeconfig

  kubectl config set-context default \
    --cluster=cluster1 \
    --user=system:node:worker \
    --kubeconfig=/srv/kubeconfigs/worker-c1.kubeconfig

  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/worker-c1.kubeconfig
}
# cluster 2
{
  kubectl config set-cluster cluster2  \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://192.168.2.2:6444 \
    --kubeconfig=/srv/kubeconfigs/worker-c2.kubeconfig

  kubectl config set-credentials system:node:worker \
    --client-certificate=/srv/pkis/worker.crt \
    --client-key=/srv/pkis/worker.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/worker-c2.kubeconfig

  kubectl config set-context default \
    --cluster=cluster2 \
    --user=system:node:worker \
    --kubeconfig=/srv/kubeconfigs/worker-c2.kubeconfig

  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/worker-c2.kubeconfig
}

# Copy the cert, key and the kubeconfigs to the worker
scp -i /home/vagrant/.ssh/id_rsa /srv/pkis/worker.crt \
    /srv/pkis/worker.key /srv/pkis/ca.crt \
    /srv/kubeconfigs/worker-c1.kubeconfig \
    /srv/kubeconfigs/worker-c2.kubeconfig \
    vagrant@worker:/home/vagrant/
