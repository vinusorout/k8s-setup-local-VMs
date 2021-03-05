# set up CoreDNS as DNS service for kuernetes
CLUSTER_DNS_IP_VAL="10.32.0.10" # 10th address of service cluster ip range
CLUSTER_DOMAIN_VAL="cluster.local" # cluster domain
REVERSE_CIDRS_VAL="in-addr.arpa ip6.arpa"

echo "Configuring Core DNS on cluster"
export CLUSTER_DNS_IP=${CLUSTER_DNS_IP_VAL}
export CLUSTER_DOMAIN=${CLUSTER_DOMAIN_VAL}
export REVERSE_CIDRS=${REVERSE_CIDRS_VAL}

envsubst < "coredns.yaml.sed" > "coredns.yaml"

# NOTE considering admin.kubeconfig is alresdy setup in env variables OR config file is setup in .kube/config
kubectl apply -f coredns.yaml
echo "Finished Configuring Core DNS on cluster"

#sleep for 1 minutes
sleep 60s

echo "Configuring Kong Ingress controller"
kubectl apply -f k4k8s.yaml
echo "Finished Configuring Kong Ingress controller"

#sleep for 1 minutes
sleep 60s

echo "Configuring nginx"
kubectl apply -f nginx-config.yaml
kubectl apply -f nginx-dep.yaml
kubectl apply -f nginx-service.yaml
echo "Finished Configuring nginx"

