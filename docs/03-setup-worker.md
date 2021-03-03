# Set up worker nodes of cluster

Before continue make sur you disable the **swap** permanently, otherwise you will have to disable the swap and then restart the kubelet service every time, you restart the worker node. Worker node kubelet service will not work untill you disable the swap functionlaity.

Make sure to install follwoing dependencies on worker nodes:
```
sudo apt-get -y install socat conntrack ipset
```