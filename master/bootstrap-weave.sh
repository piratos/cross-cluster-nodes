set -e

# Deploy weave
# cluster 1
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')" \
    --kubeconfig=/srv/kubeconfigs/admin1.kubeconfig \
    --server=127.0.0.1:8080
# cluster 2
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')" \
    --kubeconfig=/srv/kubeconfigs/admin2.kubeconfig \
    --server=127.0.0.1:8081
