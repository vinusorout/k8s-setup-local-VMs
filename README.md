# Kubernetes setup on local VMs
Kubernetes installation and exposing to external world is hard for local VMs, as the load balancer service of k8s need a loadbalancer public IP, which is not available for local machines. This guide walks you through setting up the kubernetes and its components locally with some details, on VMs. Also in this guide we will create the scripts to automate the process of installing the kubernetes cluster.

We will setup a single control plane and single worker cluster.

## Cluster Information
* Kubernetes version 1.20.4
* 1 Control Plane and 1 Worker node
* ETCD 3.4.14
* cni 0.9.1 (with bridge plugin)
* Kong Ingress Controller 1.1.x

## Prerequisites
* 2, Linux VM for Kubernetes Control Plane and worker node, with full network connectivity either in private network or on public network
* 1, Linux client machine to run the scripts.

If you go through the scripts, you will find more details and specific notes for commands used

### Compute Resources:
To create VMs use the **vagrant** and **virtualbox** tools, after installing these tools run follwoing command in the base directorty of this repo:
```
vagrant up
```

This will create follwoing VMs:
- kclient (where we will execute the scripts)
- kmaster-1 (for master/control plane node)
- kworker-1 (for worker node)

To ssh into the VMs use:
```
vagrant ssh kclient
```

**Note** if you decide to update the IP or Name of the VMs in [Vagrantfile](Vagrantfile), then make sure to update the file [update-hosts.sh](update-hots.sh) accordingly. And the VMs created by vagrant has default user name as vagrant and password as vagrant, also the root password is vagrant.

## TOC
1. [Generate Required Certficates and Kubeconfigs](docs/01-generate-certificates.md)
2. [Set up Control Plane](docs/02-setup-control-plane.md)
3. [Set up Worker](docs/03-setup-worker.md)
4. [Set up DNS and expose to external world with KONG and NGINX](docs/04-setup-dns-and-expose-services.md)

So let's start: [Let's start with generating the certificates](docs/01-generate-certificates.md)

