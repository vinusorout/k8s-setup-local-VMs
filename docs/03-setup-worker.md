# Set up worker nodes of cluster

Before continuing  make sure you disable the **swap** permanently, otherwise you will have to disable the swap and then restart the kubelet service every time, you restart the worker node. Worker node kubelet service will not work untill you disable the swap functionlaity.

Make sure to install following dependencies on worker nodes:
```
sudo apt-get -y install socat conntrack ipset
```

Using these scripts, we will setup the worker nodes of the cluster. These scripts will install following components:
* **containerd** the runtime enviornment to be used by kubectl to create containers. As kubernetes is deprecating the Docker runtime from version v1.22, we should avoid Docker.

* **CNI** the Container Network Interface, why we need CNI, kubernetes need some networking applications to congigure networking for its pods. Every pod gets a unique IP assigned from the POD_CIDR we assign to the pods. The CNI plugins implements simple commands like ADD, DELETE, GET to configure a network settings(like ip address, bridge etc). kubernetes uses these commands to configure pods networks. Follwoing are the CNI Plugin responsibilities defined by the CNI standards:
    - Must support arguments ADD/DEL/CHECK
    - Must support parameters container id, network ns etc.
    - Must manage IP address assignments to PODs
    - Must return results in a specific format

    ### CNI with bridge plugin
    In this example we are setting the CNI with bridge plugin, With bridge plugin, all containers (on the same host) are plugged into a bridge (virtual switch) that resides in the host network namespace. The containers receive one end of the veth pair with the other end connected to the bridge. An IP address is only assigned to one end of the veth pair – one residing in the container. The bridge itself can also be assigned an IP address, turning it into a gateway for the containers. Alternatively, the bridge can function purely in L2 mode and would need to be bridged to the host network interface (if other than container-to-container communication on the same host is desired). The network configuration specifies the name of the bridge to be used. If the bridge is missing, the plugin will create one on first use and, if gateway mode is used, assign it an IP that was returned by IPAM plugin via the gateway field.

    Check [10-bridge.conf](../scripts/worker/10-bridge.conf) file, in this we are setting the plugin **bridge**(to assign IPs to pods) and for IPAM plugin **host-local** (to manage ip list of PODs), we can use **dhcp** also if we have external dhcp plugin. Both these **host-local** and **dhcp** plugins are used to manage list of IPs assigned to PODs
    ```json
    {
        "cniVersion": "0.4.0",
        "name": "bridge",
        "type": "bridge",
        "bridge": "cnio0",
        "isGateway": true,
        "ipMasq": true,
        "ipam": {
            "type": "host-local",
            "ranges": [
            [{"subnet": "${POD_CIDR_FOR_WORKER}"}]
            ],
            "routes": [{"dst": "0.0.0.0/0"}]
        }
    }
    ```
    we can use other plugins like **weave** etc

* **kubelet** Kubelet is the agent that runs on each node in the cluster. The agent is responsible for making sure that the containers are running on the nodes as expected.

* **kube-proxy** This is a proxy service which runs on each node and helps in making services available to the external host. It helps in forwarding the request to correct containers and is capable of performing primitive load balancing. It makes sure that the networking environment is predictable and accessible and at the same time it is isolated as well.

To set up worker nodes, update following variables in file [set-up-worker.sh](../scripts/worker/set-up-worker.sh)

```
VMS=("kworker-1") # all the worker nodes name(hostname), seperated by space.
VMS_POD_CIDR=("10.200.1.0/24") # all the wokerer pod cidr, seperated by space.
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oUser=vagrant" # replace -oUser with username of the nodes which has admin rights on all the nodes
ROOT_CA_FILE_NAME="ca.pem"
CLUSTER_CIDR="10.200.0.0/16" # this is the ip range used by your cluster for assigning pods ip, for each worker we need to assign a POD_CIDR ex 10.200.1.0/24 that will be a subnet of this CLUSTER_CIDR
CLUSTER_DNS_IP="10.32.0.10" # 10th address of the service ip range (10.32.0.0/24)
IFNAME="enp0s8" # the interface name to be use to get the IP address of VM, if only one interface then can be leave blank

```

Now run [set-up-worker.sh](../scripts/worker/set-up-worker.sh), this will install all the worker components on servers.

to verify run following commands after a few seconds:
```
kubectl get nodes
```

Now we are done with kubernetes indtallation, lets expose this to external network with kong ingress [04-setup-dns-and-expose-services.md](04-setup-dns-and-expose-services.md)