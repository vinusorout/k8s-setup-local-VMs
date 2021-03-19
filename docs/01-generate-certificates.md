# Generating all the required Certificates and Kubeconfig files
Kubernetes requires PKI certificates for authentication over TLS, to communicate between control plance and its workers nodes, in this lab we will generate all the required certicates using the OPENSSL tool.

Kubernetes requires PKI for the following operations:
* Client certificates for the kubelet to authenticate to the API server
* Server certificate for the API server endpoint
* Client certificates for administrators of the cluster to authenticate to the API server
* Client certificates for the API server to talk to the kubelets
* Client certificate for the API server to talk to etcd
* Client certificate/kubeconfig for the controller manager to talk to the API server
* Client certificate/kubeconfig for the scheduler to talk to the API server.

## Why certificates
In kubernetes the authentication is managed by the certificates, the subject name(CN) of the certificates is consider as the user name, the subject name(O) is the group of the user belongs to. So each component of kubernetes will use its certificate as user details to call other component, for example when we execute the kubectl logs for a pod command, kubectl call the API server and then the API server contact the kubelet of worker, API server creates a valid request using its certificates and send it to worker node kubelet, then the kublet verify the requests as per the certificates.
We are setting the kubernetes authorization setting with RBAC, to check if a user in a group has some permission, use this command:
```
kubectl auth can-i get pods --as=admin --as-group=system:masters
```

## Generate all required certificates:

To generate nodes certificates update following variables in file [create-all-certs.sh](scripts/certs/create-all-certs.sh)

NOTE: In case you face Cant load ./.rnd into RNG error then Removing (or commenting out) RANDFILE = $ENV::HOME/.rnd from /etc/ssl/openssl.cnf

```
VMS=("kmaster-1" "kworker-1") # all the controller and worker nodes name(hostname), seperated by space.
VM_ROLES=("CP" "WR") # all the nodes roles CP for Control Plane and WR for worker, seperated by space.
KUBERNETES_CLUSTER_SERVICE_IP=10.32.0.1 #Always the first IP address of the range we provide(--service-cluster-ip-range=10.32.0.0/24(example can be changed as per requirements)) in for kube api server while creating control plane
KUBERNETES_EXTERNAL_DNS="" # Domain name if any of your Control Plane node.
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR -oUser=vagrant" # replace -oUser with username of the nodes which has admin rights on all the nodes
IFNAME="enp0s8" # the interface name to be use to get the IP address of VM, if only one interface then can be leave blank

```

Finally run this file in client machine(your local machine). This will generate all the required csr files for all the nodes.Now we need to sign the certificates by either your CA authority or self signed. Lets self signed as of now:

Create Root CA:
```
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kubernetes"

IF you get "Can't load ./.rnd into RNG" error, Try removing or commenting RANDFILE = $ENV::HOME/.rnd line in /etc/ssl/openssl.cnf
```
Sign each generated csr:
```
#for with .conf file like kontrol-kube-api-server.csr, there will be kcontrol_api_server_openssl and for kworker-kubelet.csr, kworker_openssl.conf
openssl x509 -req -in csr_file_name.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out new_certificate_name.pem -days 3650 -extensions ssl_client -extfile csr_file_name_openssl.conf
OR
# for without .conf, like admin.csr
openssl x509 -req -in csr_file_name.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out new_certificate_name.pem -days 3650 -extensions ssl_client

for kmaster-1 and kworker-1 following are the commands:
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kube-control-manager.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kube-control-manager-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kube-proxy.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kube-proxy-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kube-scheduler.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kube-scheduler-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kworker-1-kubelet.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kworker-1-kubelet-crt.pem -days 3650 -extensions ssl_client -extfile kworker-1_openssl.conf
openssl x509 -req -in kmaster-1-kube-api-server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kmaster-1-kube-api-server-crt.pem -days 3650 -extensions ssl_client -extfile kmaster-1_api_server_openssl.conf
openssl x509 -req -in kmaster-1-service-account.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kmaster-1-service-account-crt.pem -days 3650 -extensions ssl_client -extfile kmaster-1_api_server_openssl.conf

```

## Why kubeconfig
Kubeconfigs files are used to identify the API server, these files has important information like server ip address, certificates for authentication purpose.Lets understand follwoing two kubeconfigs:
* **admin.kubeconfig** : This kubeconfig file is used by the "kubectl" binary to run kubectl commands. Kubectl sends the command request to API server, identified by the --server address in the kubeconfig files and the certificates embadded in the kubeconfig file.
* **kubelet.kubeconfig**: This kubeconfig file is used by kubelet binary, when we first setuo the worker node, kubelet identify the API server using the --server value in its kubeconfig files. Once it call the API server, API server add the worker to its nodes and save its informations like IP etc future comunications.

NOTE: for local purpose we are using the control plane as --server ip in kubeconfig files, on clouds it is the loadbalancer ip which routes the traffic to the control planes.

## Generate kubeconfig files:
The "kubectl" command line tool used to manage the clusters, users, namespaces adn others, uses kubeconfig files to find the information it needs to choose a cluster and communicate with the API server of a cluster. By default, "kubectl" looks for file named config in the "$HOME/.kube" directory.

Run [create-kube-config.sh](../scripts/certs/create-kube-config.sh) in same directory where all the root, serveres' certificates and keys available. This script will install kubectl in client machine and will generate the required kube config files.


For client machine(we are executing commands) Copy the new generated admin.kubeconfig file to $HOME/.kube/config and edit it, update the ip address of server, make it the ip address of control plane instead of 127.0.01

In case you are not coping the file at $HOME/.kube/config then you can use this environment variable:
```
export KUBECONFIG=$HOME/.kube/admin.kubeconfig
```

This is done to avoid typing the --kubeconfig=admin.kubeconfig while running kubectl commands on client machine.

Now we are done with the certificates and configs let's start with [setting up control plane](02-setup-control-plane.md)