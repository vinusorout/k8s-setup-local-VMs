#!/bin/bash

VM_ROLE=${1:-}
KUBERNETES_CLUSTER_SERVICE_IP=${2:-}
IFNAME=${3:-}
KUBERNETES_EXTERNAL_DNS=${4:-}

CERTIFICATE_TEMP_DIR=~/cert-final
rm -rfv "$CERTIFICATE_TEMP_DIR"
mkdir -p "$CERTIFICATE_TEMP_DIR"
declare -a EXTRA_SANS

function create-vm-specific-cert(){
    current_hostname="$(hostname)"
    current_host_FQDN="$(hostname -f)"
    echo $IFNAME
    echo "Next"
    current_host_ip=$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)
    echo "current machine is $current_hostname with ip $current_host_ip"
    key_file="$CERTIFICATE_TEMP_DIR/${current_hostname}-key.pem"
    if [ "$VM_ROLE" = "CP" ]; then
        EXTRA_SANS=(
            IP.0=${current_host_ip}
            IP.1=${KUBERNETES_CLUSTER_SERVICE_IP}
            IP.2=127.0.0.1
            DNS.1=kubernetes
            DNS.2=kubernetes.default
            DNS.3=kubernetes.default.svc
            DNS.4=kubernetes.default.svc.cluster
            DNS.5=kubernetes.default.svc.cluster.local
            DNS.6=localhost
            DNS.7=$current_hostname
            DNS.8=$current_host_FQDN
        )
        if [[ ! -z "$KUBERNETES_EXTERNAL_DNS" ]]; then
            EXTRA_SANS=("${EXTRA_SANS[@]}" "DNS.9=$KUBERNETES_EXTERNAL_DNS")
        fi

        export EXTRA_SANS_STRING=$(printf -- '%s\n' "${EXTRA_SANS[@]}")
        envsubst < "openssl.template.conf" > "$CERTIFICATE_TEMP_DIR/${current_hostname}_api_server_openssl.conf"
        # Control Plane private key
        if [ -f "${key_file}" ]; then
            echo "Key file for master:$current_hostname already exists."
        else
            openssl genrsa -out "${key_file}" 2048
        fi

        # kube api server certificate, will also be used by etcd
        openssl req -new -key "${key_file}" \
            -out "$CERTIFICATE_TEMP_DIR/${current_hostname}-kube-api-server.csr" \
            -subj "/C=US/ST=None/L=None/O=Kubernetes/CN=kubernetes" \
            -config "$CERTIFICATE_TEMP_DIR/${current_hostname}_api_server_openssl.conf"
        
        # kube service account certificate
        # The Kubernetes Controller Manager leverages a key pair to generate and sign service account tokens

        openssl req -new -key "${key_file}" \
            -out "$CERTIFICATE_TEMP_DIR/${current_hostname}-service-account.csr" \
            -subj "/C=US/ST=None/L=None/O=Kubernetes/CN=service-accounts"
            
    else
        EXTRA_SANS=(
            IP.0=${current_host_ip}
            DNS.1=localhost
            DNS.2=$current_hostname
            DNS.3=$current_host_FQDN
        )
        export EXTRA_SANS_STRING=$(printf -- '%s\n' "${EXTRA_SANS[@]}")
        envsubst < "openssl.template.conf" > "$CERTIFICATE_TEMP_DIR/${current_hostname}_openssl.conf"
        if [ -f "${key_file}" ]; then
            echo "Key file for master:$current_hostname already exists."
        else
            openssl genrsa -out "${key_file}" 2048
        fi
        # for worker the O should be system:nodes
        openssl req -new -key "${key_file}" \
            -out "$CERTIFICATE_TEMP_DIR/${current_hostname}-kubelet.csr" \
            -subj "/C=US/ST=None/L=None/O=system:nodes/CN=system:node:${current_hostname}" \
            -config "$CERTIFICATE_TEMP_DIR/${current_hostname}_openssl.conf"
        fi
}

create-vm-specific-cert

sudo chmod 777 $CERTIFICATE_TEMP_DIR/*
