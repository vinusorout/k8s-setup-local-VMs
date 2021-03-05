# Kubernetes setup on local VMs
Kubernetes installation and exposing to external world is hard for local VMs, as the load balancer service of k8s need a loadbalancer public IP, which is not available for local machines. This guide walks you through setting up the kubernetes and its components locally with some details, on VMs. Also in this guide we will create the scripts to automate the process of installing the kubernetes cluster.

We will setup a single control plane and single worker cluster.

## Cluster Information
* Kubernetes version 1.20.4
* 1 Control Plane and 1 Worker node
* ETCD 3.4.14
* cni 0.9.1
* Kong Ingress Controller 1.1.x

## Prerequisites
* 2, Linux VM for Kubernetes Control Plane and worker node, with full network connectivity either in private network or on public network
* 1, Linux client machine to run the scripts.

If you go through the scripts, you will find more details and specific notes for commands used

So let's start: [Let's start with generating the certificates](docs/01-generate-certificates.md)

