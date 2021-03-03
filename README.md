# Kubernetes setup on VM or Bare Metal Machine
Kubernetes installation and exposing to external world is hard for bare metal and VMs, as the load balancer service of k8s need an loadbalancer public IP, which is not available for bare metal machines. This guide walks you through setting up the kubernetes and its components with some details, on bare metals or on VMs. Also in this guide we will create the scripts to automate the process of installing/cleaing the kubernetes.

We will setup a single conrol plane and single worker cluster.

## Cluster Information
* Kubernetes version 1.20.4
* 1 Control Plane and 1 Worker node
* ETCD 3.4.14
* cni 0.9.1
* Kong Ingress Controller 1.1.x

## Prerequisites
* 2, Linux VM for Kubernetes Control Plane and worker node, with full network connectivity either in private network or on public network
* 1, Linux client machine to run the scripts.

Next: [Let's start with generating the certificates](docs/01-generate-certificates.md)

