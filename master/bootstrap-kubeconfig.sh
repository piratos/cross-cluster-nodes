set -e

# Create kubeconfigs folder
cd /srv/kubeconfigs

# Create kube proxies kubeconfigs
# cluster 1
{
  kubectl config set-cluster cluster1 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://192.168.2.2:6443 \
    --kubeconfig=/srv/kubeconfigs/kube-proxy1.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=/srv/pkis/kube-proxy.crt \
    --client-key=/srv/pkis/kube-proxy.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/kube-proxy1.kubeconfig

  kubectl config set-context default \
    --cluster=cluster1 \
    --user=system:kube-proxy \
    --kubeconfig=/srv/kubeconfigs/kube-proxy1.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/kube-proxy1.kubeconfig
}
# cluster 2
{
  kubectl config set-cluster cluster2 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://192.168.2.2:6444 \
    --kubeconfig=/srv/kubeconfigs/kube-proxy2.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=/srv/pkis/kube-proxy.crt \
    --client-key=/srv/pkis/kube-proxy.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/kube-proxy2.kubeconfig

  kubectl config set-context default \
    --cluster=cluster2 \
    --user=system:kube-proxy \
    --kubeconfig=/srv/kubeconfigs/kube-proxy2.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/kube-proxy2.kubeconfig
}

# copy kube-proxy kubeconfigs to worker
scp -i /home/vagrant/.ssh/id_rsa /srv/kubeconfigs/kube-proxy* vagrant@worker:/home/vagrant/

# Create kube controller manager kubeconfigs
# cluster 1
{
  kubectl config set-cluster cluster1 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=/srv/kubeconfigs/kube-controller-manager1.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=/srv/pkis/kube-controller-manager.crt \
    --client-key=/srv/pkis/kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/kube-controller-manager1.kubeconfig

  kubectl config set-context default \
    --cluster=cluster1 \
    --user=system:kube-controller-manager \
    --kubeconfig=/srv/kubeconfigs/kube-controller-manager1.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/kube-controller-manager1.kubeconfig
}
# cluster 2
{
  kubectl config set-cluster cluster2 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6444 \
    --kubeconfig=/srv/kubeconfigs/kube-controller-manager2.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=/srv/pkis/kube-controller-manager.crt \
    --client-key=/srv/pkis/kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/kube-controller-manager2.kubeconfig

  kubectl config set-context default \
    --cluster=cluster2 \
    --user=system:kube-controller-manager \
    --kubeconfig=/srv/kubeconfigs/kube-controller-manager2.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/kube-controller-manager2.kubeconfig
}

# Create kube scheduler kubeconfigs
# cluster 1
{
  kubectl config set-cluster cluster1 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=/srv/kubeconfigs/kube-scheduler1.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=/srv/pkis/kube-scheduler.crt \
    --client-key=/srv/pkis/kube-scheduler.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/kube-scheduler1.kubeconfig

  kubectl config set-context default \
    --cluster=cluster1 \
    --user=system:kube-scheduler \
    --kubeconfig=/srv/kubeconfigs/kube-scheduler1.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/kube-scheduler1.kubeconfig
}
# cluster 2
{
  kubectl config set-cluster cluster2 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6444 \
    --kubeconfig=/srv/kubeconfigs/kube-scheduler2.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=/srv/pkis/kube-scheduler.crt \
    --client-key=/srv/pkis/kube-scheduler.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/kube-scheduler2.kubeconfig

  kubectl config set-context default \
    --cluster=cluster2 \
    --user=system:kube-scheduler \
    --kubeconfig=/srv/kubeconfigs/kube-scheduler2.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/kube-scheduler2.kubeconfig
}

# Create admin kubeconfigs
# cluster 1
{
  kubectl config set-cluster cluster1 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=/srv/kubeconfigs/admin1.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=/srv/pkis/admin.crt \
    --client-key=/srv/pkis/admin.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/admin1.kubeconfig

  kubectl config set-context default \
    --cluster=cluster1 \
    --user=admin \
    --kubeconfig=/srv/kubeconfigs/admin1.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/admin1.kubeconfig
}
# cluster 2
{
  kubectl config set-cluster cluster2 \
    --certificate-authority=/srv/pkis/ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6444 \
    --kubeconfig=/srv/kubeconfigs/admin2.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=/srv/pkis/admin.crt \
    --client-key=/srv/pkis/admin.key \
    --embed-certs=true \
    --kubeconfig=/srv/kubeconfigs/admin2.kubeconfig

  kubectl config set-context default \
    --cluster=cluster2 \
    --user=admin \
    --kubeconfig=/srv/kubeconfigs/admin2.kubeconfig
  kubectl config use-context default --kubeconfig=/srv/kubeconfigs/admin2.kubeconfig
}

# ETCD encryption
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > /srv/manifests/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
