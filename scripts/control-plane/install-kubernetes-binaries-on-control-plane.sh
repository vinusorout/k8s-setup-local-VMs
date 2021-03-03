#!/bin/bash

CONTROL_PLANE_VM=${1:-}
ROOT_CA_FILE_NAME=${2:-}
ROOT_CA_KEY_FILE_NAME=${3:-}
SERV_IP_RANGE=${4:-}
NODE_PORT_RANGE=${5:-}
CIDR=${6:-}
CLUSTR_NAME=${7:-}

api_server_file=/usr/local/bin/kube-apiserver

function install-cotrol-plane-components(){
    if [ -f "$api_server_file" ]; then
        echo "${api_server_file} exists."
    else
        echo "${api_server_file} does not exist."
        CURRENT_HOST_IP=$(ip addr | grep -m 1 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
        current_hostname="$(hostname)"
        echo "Variables on control plane ${current_hostname}: ${CONTROL_PLANE_VM}, ${ROOT_CA_FILE_NAME}, ${ROOT_CA_KEY_FILE_NAME}, ${SERV_IP_RANGE}, ${NODE_PORT_RANGE}, ${CIDR}, ${CLUSTR_NAME}"

        echo "Downloading control plane binaries on ${current_hostname}"
        wget -q --show-progress --https-only --timestamping \
            "https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kube-apiserver" \
            "https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kube-controller-manager" \
            "https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kube-scheduler" \
            "https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kubectl"
        
        chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
        sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/

        sudo mkdir -p /var/lib/kubernetes/
        sudo mkdir -p /etc/kubernetes/config

        # move kube api server required certificates and ecription key config of etcd
        sudo cp $ROOT_CA_FILE_NAME $ROOT_CA_KEY_FILE_NAME encryption-data-config.yaml kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ./${current_hostname}* /var/lib/kubernetes/

        ETCD_SERVERS=""
        idx=0
        for vm in "${CONTROL_PLANE_VM[@]}"; do
            ip_addr=$(getent hosts ${vm} | awk '{print $1}')
            etcd_ip=""
            if [[ "$vm" == "$current_hostname" ]]; then
                etcd_ip="https://${CURRENT_HOST_IP}:2379"
            else
                etcd_ip="https://${ip_addr}:2379"
            fi
            echo "${etcd_ip}"
            if [ $idx -ne 0 ]
            then
                curr_val=${ETCD_SERVERS}
                ETCD_SERVERS="${curr_val},${etcd_ip}"
            else
                ETCD_SERVERS="${etcd_ip}"
            fi
            ((idx=idx+1))
        done
        echo "Final string for etcd servers ${ETCD_SERVERS}"

        export CONTROL_PLANE_IP=${CURRENT_HOST_IP}
        export API_SERVER_COUNT=${idx}
        export ROOT_CA_FILE_LOC=/var/lib/kubernetes/${ROOT_CA_FILE_NAME}
        export SERVER_CRT_FILE_LOC=/var/lib/kubernetes/${current_hostname}-kube-api-server-crt.pem
        export SERVER_KEY_FILE_LOC=/var/lib/kubernetes/${current_hostname}-key.pem
        export ETCD_SERVERS_FINAL=${ETCD_SERVERS}
        export ENCRYPTION_FILE_LOC=/var/lib/kubernetes/encryption-data-config.yaml
        export SERVICE_ACCOUNT_CRT_FILE_LOC=/var/lib/kubernetes/${current_hostname}-service-account-crt.pem
        export SERVICE_ACCOUNT_KEY_FILE_LOC=/var/lib/kubernetes/${current_hostname}-key.pem
        export SERVICE_CLUSTER_IP_RANGE=${SERV_IP_RANGE} # This is the range of ips, used by kubernetes to assign ip address to its services, the first ip is reserved for the api server and 10th ip is reserved for DNS
        export SERVICE_NODE_PORT_RANGE=${NODE_PORT_RANGE} # Default is 30000-32767, but we are using from 1, bacause for bare-metal we will use port 80

        # kube controller manager
        export CLUSTER_CIDR=${CIDR} # this is the ip range used by your cluster for assigning pods ip, for each worker we need to assign a POD_CIDR ex 10.200.1.0/24 that will be a subnet of this CLUSTER_CIDR
        export CLUSTER_NAME=${CLUSTR_NAME}
        export ROOT_CA_KEY_FILE_LOC=/var/lib/kubernetes/${ROOT_CA_KEY_FILE_NAME}
        export KUBE_CONTROLLER_MANAGER_KUBECONFIG=/var/lib/kubernetes/kube-controller-manager.kubeconfig

        # kube scheduler:
        sudo cp  kube-scheduler.yaml /etc/kubernetes/config/
        export KUBE_SCHEDULER_CONFIG=/etc/kubernetes/config/kube-scheduler.yaml

        envsubst < "kube-apiserver.env" > "/etc/kubernetes/kube-apiserver.env"

        sudo mv kube-apiserver.service /etc/systemd/system/
        sudo mv kube-controller-manager.service /etc/systemd/system/
        sudo mv kube-scheduler.service /etc/systemd/system/

        sudo systemctl daemon-reload
        sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
        sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler

    fi
}

install-cotrol-plane-components

echo "sleeping the commands for 120 seconds"
sleep 120s

# configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node.
# Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.
# Run this on only one control plane
FIRST_CONTROL_PLANE="${CONTROL_PLANE_VM[0]}"
Hostname="$(hostname)"
echo "first control vm is: ${FIRST_CONTROL_PLANE} and current host name is ${Hostname}"
if [[ "$FIRST_CONTROL_PLANE" == "$Hostname" ]]; then
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
fi