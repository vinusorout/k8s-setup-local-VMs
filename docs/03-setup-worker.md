# Set up worker nodes of cluster

Before continuing  make sure you disable the **swap** permanently, otherwise you will have to disable the swap and then restart the kubelet service every time, you restart the worker node. Worker node kubelet service will not work untill you disable the swap functionlaity.

Make sure to install following dependencies on worker nodes:
```
sudo apt-get -y install socat conntrack ipset
```

Using these scripts, we will setup the worker nodes of the cluster. These scripts will install following components:
* **containerd** the runtime enviornment to be used by kubectl to create containers. As kubernetes is deprecating the Docker runtime from version v1.22, we should avoid Docker.

* **CNI** the Container Network Interface, why we need CNI, kubernetes need some networking applications to congigure networking for its pods. Every pod gets a unique IP assigned from the POD_CIDR we assign to the pods. The CNI plugins implements simple commands like ADD, DELETE, GET to configure a network settings(like ip address, bridge etc). kubernetes uses these commands to configure pods networks

* **kubelet** Kubelet is the agent that runs on each node in the cluster. The agent is responsible for making sure that the containers are running on the nodes as expected.

* **kube-proxy** This is a proxy service which runs on each node and helps in making services available to the external host. It helps in forwarding the request to correct containers and is capable of performing primitive load balancing. It makes sure that the networking environment is predictable and accessible and at the same time it is isolated as well.

To set up worker nodes, update following variables in file [set-up-worker.sh](../scripts/worker/set-up-worker.sh)

```
VMS=("kworker") # all the worker nodes name(hostname), seperated by space.
VMS_POD_CIDR=("10.200.1.0/24") # all the wokerer pod cidr, seperated by space.
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oUser=username" # replace -oUser with username of the nodes which has admin rights on all the nodes
ROOT_CA_FILE_NAME="ca.pem"
CLUSTER_CIDR="10.200.0.0/16" # this is the ip range used by your cluster for assigning pods ip, for each worker we need to assign a POD_CIDR ex 10.200.1.0/24 that will be a subnet of this CLUSTER_CIDR
CLUSTER_DNS_IP="10.32.0.10" # 10th address of the service ip range (10.32.0.0/24)
```

Now run [set-up-worker.sh](../scripts/worker/set-up-worker.sh), this will install all the worker components on servers.

to verify run following commands after a few seconds:
```
kubectl get nodes
```

Now we are done with kubernetes indtallation, lets expose this to external network with kong ingress [04-setup-dns-and-expose-services.md](04-setup-dns-and-expose-services.md)