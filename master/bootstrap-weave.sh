set -e

# Deploy weave
# cluster 1
kubectl apply -f "/srv/master/weave1.yaml" \
    --kubeconfig=/srv/kubeconfigs/admin1.kubeconfig \
    --server=127.0.0.1:8080
# cluster 2
kubectl apply -f "/srv/master/weave2.yaml" \
    --kubeconfig=/srv/kubeconfigs/admin2.kubeconfig \
    --server=127.0.0.1:8081
