#!/bin/bash

VMS=("kcontrol" "kworker") # all the controller and worker nodes name(hostname), seperated by space.
VM_ROLES=("CP" "WR") # all the nodes roles CP for Control Plane and WR for worker, seperated by space.
KUBERNETES_CLUSTER_SERVICE_IP=10.32.0.1 #Always the first IP address of the range we provide(--service-cluster-ip-range=10.32.0.0/24(example can be changed as per requirements)) in for kube api server while creating control plane
KUBERNETES_EXTERNAL_DNS="" # Domain name if any of your Control Plane node.
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR -oUser=username" # replace -oUser with username of the nodes which has admin rights on all the nodes

mkdir -p certificates
rm -f ./certificates/*

echo "Current dir is"
echo $PWD

# in kubernetes the authentication is managed by the certificates, the subject name(CN) of the certificates is consider as the user name
# the subject name(O) is the group of the user belongs to
# we are setting the kubernetes authorization setting with RBAC
# to check if a use in a group has some permission use this command:
#kubectl auth can-i get pods --as=admin --as-group=system:masters

#admin client certificate
admin_key_file="$PWD/certificates/admin-key.pem"
if [ -f "${admin_key_file}" ]; then
    echo "Key file for master:$admin_key_file already exists."
else
    openssl genrsa -out "${admin_key_file}" 2048
fi

# O should be system:masters other wise kubernetes wont give permission to admin
openssl req -new -key "${admin_key_file}" \
    -out "$PWD/certificates/admin.csr" \
    -subj "/C=US/ST=None/L=None/O=system:masters/CN=admin"

#control manager client certificate
kube_control_manager_key_file="$PWD/certificates/kube-control-manager-key.pem"
if [ -f "${kube_control_manager_key_file}" ]; then
    echo "Key file for master:$kube_control_manager_key_file already exists."
else
    openssl genrsa -out "${kube_control_manager_key_file}" 2048
fi

openssl req -new -key "${kube_control_manager_key_file}" \
    -out "$PWD/certificates/kube-control-manager.csr" \
    -subj "/C=US/ST=None/L=None/O=system:kube-controller-manager/CN=system:kube-controller-manager"

#kube proxy client certificate
kube_proxy_key_file="$PWD/certificates/kube-proxy-key.pem"
if [ -f "${kube_proxy_key_file}" ]; then
    echo "Key file for master:$kube_proxy_key_file already exists."
else
    openssl genrsa -out "${kube_proxy_key_file}" 2048
fi

openssl req -new -key "${kube_proxy_key_file}" \
    -out "$PWD/certificates/kube-proxy.csr" \
    -subj "/C=US/ST=None/L=None/O=system:node-proxier/CN=system:kube-proxy"

#kube scheduler client certificate
kube_scheduler_key_file="$PWD/certificates/kube-scheduler-key.pem"
if [ -f "${kube_scheduler_key_file}" ]; then
    echo "Key file for master:$kube_scheduler_key_file already exists."
else
    openssl genrsa -out "${kube_scheduler_key_file}" 2048
fi

openssl req -new -key "${kube_scheduler_key_file}" \
    -out "$PWD/certificates/kube-scheduler.csr" \
    -subj "/C=US/ST=None/L=None/O=system:kube-scheduler/CN=system:kube-scheduler"

idx=0
for vm in "${VMS[@]}"; do
    vm_role="${VM_ROLES[$idx]}"
    # Copy scripts on the particular machine
    scp $VM_SSH_OPTIONS create-vm-specific-cert.sh openssl.template.conf "${vm}:~/"

    # run command to create node specific certificates
    ssh $VM_SSH_OPTIONS -t "$vm" "
        sudo chmod +x ~/create-vm-specific-cert.sh
        sudo ~/create-vm-specific-cert.sh $vm_role $KUBERNETES_CLUSTER_SERVICE_IP $KUBERNETES_EXTERNAL_DNS"
    
    # Copy the generated certificates and keys on client machines(current working machine)
    scp $VM_SSH_OPTIONS "${vm}:~/cert-final/*" ./certificates/

    ((idx=idx+1))
done

sudo chmod 777 ./*
sudo chmod 777 ./certificates/*