#!/bin/bash

POD_CIDR=${1:-}
CLUSTER_CIDR=${2:-}
ROOT_CA_FILE_NAME=${3:-}
CLUSTER_DNS_IP=${4:-} # Always the 10th address of serive range for example 10.32.0.10 of 10.32.0.0/24

kubelet_server_file=/usr/local/bin/kubelet 

function install-cotrol-plane-components(){
    if [ -f "$kubelet_server_file" ]; then
        echo "${kubelet_server_file} exists."
    else
        echo "${kubelet_server_file} does not exist."
        CURRENT_HOST_IP=$(ip addr | grep -m 1 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
        current_hostname="$(hostname)"
        echo "Variables on worker ${current_hostname}: ${POD_CIDR}, ${CLUSTER_CIDR}, ${ROOT_CA_FILE_NAME}, ${CLUSTER_DNS_IP}"

        echo "Downloading worker binaries on ${current_hostname}"
        wget -q --show-progress --https-only --timestamping \
            https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.20.0/crictl-v1.20.0-linux-amd64.tar.gz \
            https://github.com/opencontainers/runc/releases/download/v1.0.0-rc93/runc.amd64 \
            https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz \
            https://github.com/containerd/containerd/releases/download/v1.4.3/containerd-1.4.3-linux-amd64.tar.gz \
            https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kubectl \
            https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kube-proxy \
            https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kubelet
        
        sudo mkdir -p \
            /etc/cni/net.d \
            /opt/cni/bin \
            /var/lib/kubelet \
            /var/lib/kube-proxy \
            /var/lib/kubernetes \
            /var/run/kubernetes
        
        mkdir containerd
        tar -xvf crictl-v1.20.0-linux-amd64.tar.gz
        tar -xvf containerd-1.4.3-linux-amd64.tar.gz -C containerd
        sudo tar -xvf cni-plugins-linux-amd64-v0.9.1.tgz -C /opt/cni/bin/
        sudo mv runc.amd64 runc
        chmod +x crictl kubectl kube-proxy kubelet runc 
        sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
        sudo mv containerd/bin/* /bin/

        # Configure CNI Networking
        echo "Configure CNI Networking on ${current_hostname}"
        export POD_CIDR_FOR_WORKER=${POD_CIDR}
        export ROOT_CA_FILE=${ROOT_CA_FILE_NAME}
        export CLUSTER_DNS_IP_FOR_POD=${CLUSTER_DNS_IP}
        export CLUSTER_CIDR_FOR_POD=${CLUSTER_CIDR}
        export CLUSTER_DOMAIN="cluster.local"
        export TLS_CERT_FILE="${current_hostname}-kubelet-crt.pem"
        export TLS_PRIVATE_KEY_FILE="${current_hostname}-key.pem"
        envsubst < "10-bridge.conf" > "/etc/cni/net.d/10-bridge.conf"
        envsubst < "99-loopback.conf" > "/etc/cni/net.d/99-loopback.conf"

        #Configure containerd
        echo "Configure containerd on ${current_hostname}"
        sudo mkdir -p /etc/containerd/
        envsubst < "config.toml" > "/etc/containerd/config.toml"
        envsubst < "containerd.service" > "/etc/systemd/system/containerd.service"

        # Configure kubelet on worker
        echo "configuring kubelet on ${current_hostname}"
        sudo cp ${current_hostname}-key.pem ${current_hostname}-kubelet-crt.pem  /var/lib/kubelet/
        sudo cp ${current_hostname}_kubelet.kubeconfig /var/lib/kubelet/kubeconfig
        sudo cp ${ROOT_CA_FILE_NAME} /var/lib/kubernetes/

        envsubst < "kubelet-config.yaml" > "/var/lib/kubelet/kubelet-config.yaml"

        sudo cp kubelet.service /etc/systemd/system/

        # Kube Proxy
        echo "Configuring kube proxy on ${current_hostname}"
        sudo cp kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
        envsubst < "kube-proxy-config.yaml" > "/var/lib/kube-proxy/kube-proxy-config.yaml"
        sudo cp kube-proxy.service /etc/systemd/system/

        sudo systemctl daemon-reload
        sudo systemctl enable containerd
        sudo systemctl start containerd

        sleep 10s

        sudo systemctl daemon-reload
        sudo systemctl enable kubelet kube-proxy
        sudo systemctl start kubelet kube-proxy

    fi
}

install-cotrol-plane-components