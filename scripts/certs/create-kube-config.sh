# install kubectl on client machine (the machine we are currenttly working)
sudo chmod +x install-kubectl.sh
sudo ./install-kubectl.sh

# KUBECONFIGS:
# which enable Kubernetes clients(kubelet and kupe-proxy of workers, kubectl of clients etc) to locate and authenticate to the Kubernetes API Servers.

# NOTE: Here we are considering only one control and one/multi workers nodes. If you need multiple control planes in a single cluster, you need a load balancer fuctionality, which will redirect the traffic to all the control planes.
CLUSTER_ACCES_ADDRESS=192.168.71.137 #Single control machine IP address Or loadbalancer IP address in case of multi control planes
CONTROL_PLANE_VMS=("kcontrol") # space seperated control plane vms hostnames
WORKER_VMS=("kworker") # space seperated worker vms hostnames
ROOT_CA_FILE_NAME="ca.pem" # Root CA certificate file name
ROOT_CA_KEY_FILE_NAME="ca-key.pem"
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oUser=username" # replace -oUser with username of the nodes which has admin rights on all the nodes
CLUSTER_NAME="my-kubernetes-cluster"

# Kubelet config files
# The --embed-certs flag is needed to generate a standalone kubeconfig, that will work as-is on another host. If you want set it true and keep the certificates and key files in each nodes and provide their locations
idx=0
for worker_vm in "${WORKER_VMS[@]}"; do
    kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=${ROOT_CA_FILE_NAME} --embed-certs=true --server=https://${CLUSTER_ACCES_ADDRESS}:6443 --kubeconfig=${worker_vm}_kubelet.kubeconfig
    kubectl config set-credentials system:node:${worker_vm} --client-certificate=${worker_vm}-kubelet-crt.pem --client-key=${worker_vm}-key.pem --embed-certs=true --kubeconfig=${worker_vm}_kubelet.kubeconfig
    kubectl config set-context default --cluster=${CLUSTER_NAME} --user=system:node:${worker_vm} --kubeconfig=${worker_vm}_kubelet.kubeconfig
    kubectl config use-context default --kubeconfig=${worker_vm}_kubelet.kubeconfig
    ((idx=idx+1))
done

#kube-proxy config files
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=${ROOT_CA_FILE_NAME} --embed-certs=true --server=https://${CLUSTER_ACCES_ADDRESS}:6443 --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials system:kube-proxy --client-certificate=kube-proxy-crt.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default --cluster=${CLUSTER_NAME} --user=system:kube-proxy --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

#kube-controller-manager config files
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=${ROOT_CA_FILE_NAME} --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-credentials system:kube-controller-manager --client-certificate=kube-control-manager-crt.pem --client-key=kube-control-manager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-context default --cluster=${CLUSTER_NAME} --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

#kube-scheduler config files
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=${ROOT_CA_FILE_NAME} --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-credentials system:kube-scheduler --client-certificate=kube-scheduler-crt.pem --client-key=kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-context default --cluster=${CLUSTER_NAME} --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

# admin congif files
kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=${ROOT_CA_FILE_NAME} --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig=admin.kubeconfig
kubectl config set-credentials admin --client-certificate=admin-crt.pem --client-key=admin-key.pem --embed-certs=true --kubeconfig=admin.kubeconfig
kubectl config set-context default --cluster=${CLUSTER_NAME} --user=admin --kubeconfig=admin.kubeconfig
kubectl config use-context default --kubeconfig=admin.kubeconfig


# cretae a data encription key used by kube API server. The kube-apiserver process accepts an argument --encryption-provider-config that controls how API data is encrypted in etcd.
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > encryption-data-config.yaml <<EOF
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


# Copy certificates and kube config files on workers and conrtol planes
# control planes
# follwoing certificates and keys will be copied on control plane, let say contro plane name is kcontrol
# encryption-data-config.yaml
# root-ca.crt
# root-ca.key
# kcontrol.key
# kcontrol-kube-api-server.crt
# kcontrol-service-account.crt
# kube-controller-manager.kubeconfig
# kube-scheduler.kubeconfig
# admin.kubeconfig
idx=0
for vm in "${CONTROL_PLANE_VMS[@]}"; do
    scp $VM_SSH_OPTIONS ./${vm}* "${vm}:~/"
    scp $VM_SSH_OPTIONS ./$ROOT_CA_FILE_NAME "${vm}:~/"
    scp $VM_SSH_OPTIONS ./$ROOT_CA_KEY_FILE_NAME "${vm}:~/"
    scp $VM_SSH_OPTIONS ./encryption-data-config.yaml "${vm}:~/"
    scp $VM_SSH_OPTIONS ./kube-controller-manager.kubeconfig "${vm}:~/"
    scp $VM_SSH_OPTIONS ./kube-scheduler.kubeconfig "${vm}:~/"
    scp $VM_SSH_OPTIONS ./admin.kubeconfig "${vm}:~/"
    ((idx=idx+1))
done

# worker
# follwoing certificates and keys will be copied on worker node, let say worker node name is kworker
# root-ca.crt
# kworker.key
# kworker_kublet.crt
# kworker_kubelet.kubeconfig
# kube-proxy.kubeconfig
for vm in "${WORKER_VMS[@]}"; do
    scp $VM_SSH_OPTIONS ./${vm}* "${vm}:~/"
    scp $VM_SSH_OPTIONS ./$ROOT_CA_FILE_NAME "${vm}:~/"
    scp $VM_SSH_OPTIONS ./kube-proxy.kubeconfig "${vm}:~/"
    ((idx=idx+1))
done
