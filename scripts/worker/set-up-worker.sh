#!/bin/bash

VMS=("kworker-1") # all the worker nodes name(hostname), seperated by space.
VMS_POD_CIDR=("10.200.1.0/24") # all the wokerer pod cidr, seperated by space.
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oUser=vagrant" # replace -oUser with username of the nodes which has admin rights on all the nodes
ROOT_CA_FILE_NAME="ca.pem"
CLUSTER_CIDR="10.200.0.0/16" # this is the ip range used by your cluster for assigning pods ip, for each worker we need to assign a POD_CIDR ex 10.200.1.0/24 that will be a subnet of this CLUSTER_CIDR
CLUSTER_DNS_IP="10.32.0.10" # 10th address of the service ip range (10.32.0.0/24)
IFNAME="enp0s8" # the interface name to be use to get the IP address of VM, if only one interface then can be leave blank

# install etcd on each control plane
idx=0
for vm in "${VMS[@]}"; do
    POD_CIDR="${VMS_POD_CIDR[$idx]}"
    scp $VM_SSH_OPTIONS kubelet-config.yaml kubelet.service install-kubernetes-binaries-on-worker.sh 10-bridge.conf 99-loopback.conf config.toml containerd.service kube-proxy-config.yaml kube-proxy.service "${vm}:~/"

    # run command to create node specific certificates
    ssh $VM_SSH_OPTIONS -t "$vm" "
        sudo chmod +x ~/install-kubernetes-binaries-on-worker.sh
        sudo ~/install-kubernetes-binaries-on-worker.sh $POD_CIDR $CLUSTER_CIDR $ROOT_CA_FILE_NAME $CLUSTER_DNS_IP $IFNAME"
    ((idx=idx+1))
done
