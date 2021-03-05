# Set up control plane nodes of cluster

Using these scripts, we will setup the control plane of the cluster. These scripts will install follwoing components:
* **etcd**: A distributed, consistent key-value store system, Kubernetes uses etcd to store all its data – its configuration data, its state, and its metadata. Kubernetes is a distributed system, so it needs a distributed data store like etcd

* **Kubenetes API server**: The API server is the gateway to the Kubernetes cluster. This allow applications to communicate with one another. It is the front-end for the Kubernetes control plane. It is designed to scale horizontally — that is, it scales by deploying more instances. The users, management devices, and command line interfaces all talk to the API server to interact with the Kubernetes cluster.

* **Kubernetes Scheduler**: The Kubernetes scheduler is a control plane process which assigns Pods to Nodes. The scheduler determines which Nodes are valid placements for each Pod in the scheduling queue according to constraints and available resources. The scheduler then ranks each valid Node and binds the Pod to a suitable Node

* **Kubernetes Controller Manager**: The Kubernetes Controller Manager is a daemon that embeds the core control loops (also known as “controllers”) shipped with Kubernetes. Basically, a controller watches the state of the cluster through the API Server watch feature and, when it gets notified, it makes the necessary changes attempting to move the current state towards the desired state. Some examples of controllers that ship with Kubernetes include the Replication Controller, Endpoints Controller, and Namespace Controller.

To set up control plane update follwoing variables in file [set-up-control-plane.sh](../scripts/control-plane/set-up-control-plane.sh)
Read the comments in front of the variables to get more understanding about the required variables of kubernetes.
```
VMS=("kcontrol") # all the controller nodes name(hostname), seperated by space.
KUBERNETES_CLUSTER_SERVICE_IP=10.32.0.1 #Always the first IP address of the range we provide(--service-cluster-ip-range=10.32.0.0/24(example can be changed as per requirements)) in for kube api server while creating control plane
KUBERNETES_EXTERNAL_DNS="" # Domain name if any of your Control Plane node.
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oUser=username" # replace -oUser with username of the nodes which has admin rights on all the nodes
ROOT_CA_FILE_NAME="root-ca.crt"
ROOT_CA_KEY_FILE_NAME="root-ca.key"
SERVICE_CLUSTER_IP_RANGE="10.32.0.0/24" # This is the range of ips, used by kubernetes to assign ip address to its services like DNS and to user defined services (ClusterIP, NodePort, Loadbalancer etc), the first ip is reserved for the api server and 10th ip is reserved for DNS
SERVICE_NODE_PORT_RANGE="1-32767" # Default is 30000-32767, but we are using from 1, bacause for bare-metal we will use port 80
CLUSTER_CIDR="10.200.0.0/16" # this is the ip range used by your cluster for assigning pods ip, for each worker we need to assign a POD_CIDR ex 10.200.1.0/24 that will be a subnet of this CLUSTER_CIDR
CLUSTER_NAME="my-kubernetes-cluster"
```

Now run [set-up-control-plane.sh](../scripts/control-plane/set-up-control-plane.sh), this will install all the control plane components on servers.

to verify if cluster, is working check using the kubectl command:
```
kubectl cluster-info
```

In file [install-kubernetes-binaries-on-control-plane.sh](../scripts/control-plane/install-kubernetes-binaries-on-control-plane.sh) in last steps we creates some RBAC role and Role binding so that kube-apiserver(user name kubernetes, setup in the CN while creating control plane certificates) can communicate with kubelet service of worker for some operations like get logs etc. If you decide to change the CN of control plane make sure to update the script to use the updated name. other wise some usefull kubectl commands like **exec**, **logs** wont work.

Now we are done with the control plane setup, let's start with [setting up worker](03-setup-worker.md)