#!/bin/bash

VMS=("kcontrol") # all the controller nodes name(hostname), seperated by space.
KUBERNETES_CLUSTER_SERVICE_IP=10.32.0.1 #Always the first IP address of the range we provide(--service-cluster-ip-range=10.32.0.0/24(example can be changed as per requirements)) in for kube api server while creating control plane
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oUser=username" # replace -oUser with username of the nodes which has admin rights on all the nodes
ROOT_CA_FILE_NAME="ca.pem"
ROOT_CA_KEY_FILE_NAME="ca-key.pem"
SERVICE_CLUSTER_IP_RANGE="10.32.0.0/24" # This is the range of ips, used by kubernetes to assign ip address to its services like DNS and to user defined services (ClusterIP, NodePort, Loadbalancer etc), the first ip is reserved for the api server and 10th ip is reserved for DNS
SERVICE_NODE_PORT_RANGE="1-32767" # Default is 30000-32767, but we are using from 1, bacause for bare-metal we will use port 80
CLUSTER_CIDR="10.200.0.0/16" # this is the ip range used by your cluster for assigning pods ip, for each worker we need to assign a POD_CIDR ex 10.200.1.0/24 that will be a subnet of this CLUSTER_CIDR
CLUSTER_NAME="my-kubernetes-cluster"

# install etcd on each control plane
idx=0
for vm in "${VMS[@]}"; do
    scp $VM_SSH_OPTIONS kube-apiserver.env install-etcd.sh etcd.service etcd.service.env kube-apiserver.service install-kubernetes-binaries-on-control-plane.sh kube-scheduler.yaml kube-controller-manager.service kube-scheduler.service "${vm}:~/"

    # run command to create node specific certificates
    ssh $VM_SSH_OPTIONS -t "$vm" "
        sudo chmod +x ~/install-etcd.sh
        sudo ~/install-etcd.sh $VMS $ROOT_CA_FILE_NAME
        sudo chmod +x ~/install-kubernetes-binaries-on-control-plane.sh
        sudo ~/install-kubernetes-binaries-on-control-plane.sh $VMS $ROOT_CA_FILE_NAME $ROOT_CA_KEY_FILE_NAME $SERVICE_CLUSTER_IP_RANGE $SERVICE_NODE_PORT_RANGE $CLUSTER_CIDR $CLUSTER_NAME"
    ((idx=idx+1))
done
