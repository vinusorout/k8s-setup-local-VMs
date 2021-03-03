#!/bin/bash

CONTROL_PLANE_VM=${1:-}
ROOT_CA_FILE_NAME=${2:-}

etcd_file=/etc/systemd/system/etcd.service

function install-etcd(){
    if [ -f "$etcd_file" ]; then
        echo "$etcd_file exists."
    else 
        echo "$etcd_file does not exist."
        CURRENT_HOST_IP=$(ip addr | grep -m 1 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
        current_hostname="$(hostname)"
        ETCD_NAME=$(hostname -s)

        wget https://github.com/etcd-io/etcd/releases/download/v3.4.14/etcd-v3.4.14-linux-amd64.tar.gz
        tar -xvf etcd-v3.4.14-linux-amd64.tar.gz
        sudo mv etcd-v3.4.14-linux-amd64/etcd* /usr/local/bin/
        sudo mkdir -p /etc/etcd /var/lib/etcd
        sudo chmod 700 /var/lib/etcd

        # Copy the certificates used by etcd, these certificates are alredy moved by our certs scripts.
        sudo cp ${ROOT_CA_FILE_NAME} ${current_hostname}-key.pem ${current_hostname}-kube-api-server-crt.pem /etc/etcd/

        ETCD_CERT_FILE=/etc/etcd/${current_hostname}-kube-api-server-crt.pem
        ETCD_CERT_KEY_FILE=/etc/etcd/${current_hostname}-key.pem
        ROOT_CA_FILE_LOC=/etc/etcd/${ROOT_CA_FILE_NAME}

        INITIAL_CLUSTERS=""
        idx=0
        for vm in "${CONTROL_PLANE_VM[@]}"; do
            ip_addr=$(getent hosts ${vm} | awk '{print $1}')
            vm_cluster_ip=""
            if [[ "$vm" == "$current_hostname" ]]; then
                vm_cluster_ip="${vm}=https://${CURRENT_HOST_IP}:2380"
            else
                vm_cluster_ip="${vm}=https://${ip_addr}:2380"
            fi
            echo "${vm_cluster_ip}"
            if [ $idx -ne 0 ]
            then
                curr_val=${INITIAL_CLUSTERS}
                INITIAL_CLUSTERS="${curr_val},${vm_cluster_ip}"
            else
                INITIAL_CLUSTERS="${vm_cluster_ip}"
            fi
            ((idx=idx+1))
        done
        echo "Final string for INITIAL_CLUSTERS ${INITIAL_CLUSTERS}"
        # Set up en variables
        echo "Setting up env variables"
        export INITIAL_CLUSTERS_FINAL=${INITIAL_CLUSTERS}
        export ETCD_NAME_FINAL=${ETCD_NAME}
        export ETCD_CERT_FILE_LOC=${ETCD_CERT_FILE}
        export ETCD_CERT_KEY_FILE_LOC=${ETCD_CERT_KEY_FILE}
        export ROOT_CA_FILE_LOC_FINAL=${ROOT_CA_FILE_LOC}
        export CURRENT_HOST_IP_ADDR=${CURRENT_HOST_IP}

        # ENV Variable informations availabe at https://etcd.io/docs/v3.4.0/op-guide/configuration/#--trusted-ca-file
        sudo mkdir -p /etc/kubernetes
        envsubst < etcd.service.env | sudo tee /etc/kubernetes/etcd.env
        sudo mv etcd.service /etc/systemd/system/

        sudo systemctl daemon-reload
        sudo systemctl enable etcd
        sudo systemctl start etcd
        echo "Finished Setting up etcd on ${ETCD_NAME}"
    fi
}

install-etcd
