# Generating all the required Certificates and Kubeconfig files
Kubernetes requires PKI certificates for authentication over TLS, to communicate between control plance and its workers nodes, in this lab we will generate all the required certicates using the CFSL tool.

Kubernetes requires PKI for the following operations:
* Client certificates for the kubelet to authenticate to the API server
* Server certificate for the API server endpoint
* Client certificates for administrators of the cluster to authenticate to the API server
* Client certificates for the API server to talk to the kubelets
* Client certificate for the API server to talk to etcd
* Client certificate/kubeconfig for the controller manager to talk to the API server
* Client certificate/kubeconfig for the scheduler to talk to the API server.


## Generate all required certificates:

To generate nodes certificates update following variables in file [create-all-certs.sh](scripts/certs/create-all-certs.sh)

```
VMS=("kcontrol" "kworker") # all the controller and worker nodes name(hostname), seperated by space.
VM_ROLES=("CP" "WR") # all the nodes roles CP for Control Plane and WR for worker, seperated by space.
KUBERNETES_CLUSTER_SERVICE_IP=10.32.0.1 #Always the first IP address of the range we provide(--service-cluster-ip-range=10.32.0.0/24(example can be changed as per requirements)) in for kube api server while creating control plane.
KUBERNETES_EXTERNAL_DNS="" # Domain name if any of your Control Plane node.
VM_SSH_OPTIONS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR -oUser=username" # replace -oUser with username of the nodes which has admin rights on all the nodes
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

for kcontrol and kworker following are the commands:
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kube-control-manager.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kube-control-manager-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kube-proxy.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kube-proxy-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kube-scheduler.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kube-scheduler-crt.pem -days 3650 -extensions ssl_client
openssl x509 -req -in kworker-kubelet.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kworker-kubelet-crt.pem -days 3650 -extensions ssl_client -extfile kworker_openssl.conf
openssl x509 -req -in kcontrol-kube-api-server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kcontrol-kube-api-server-crt.pem -days 3650 -extensions ssl_client -extfile kcontrol_api_server_openssl.conf
openssl x509 -req -in kcontrol-service-account.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out kcontrol-service-account-crt.pem -days 3650 -extensions ssl_client -extfile kcontrol_api_server_openssl.conf

```

## Generate kubeconfig files:
The "kubectl" command line tool used to manage the clusters, users, namespaces adn others, uses kubeconfig files to find the information it needs to choose a cluster and communicate with the API server of a cluster. By default, "kubectl" looks for file named config in the "$HOME/.kube" directory.

Run [create-kube-config.sh](../scripts/certs/create-kube-config.sh) in same directory where all the root, serveres' certificates and keys available. This script will install kubectl in client machine and will generate the required kube config files.



Now we are done with the certificates and configs let's start with [setting up control plane](02-setup-control-plane.md)

For client machine(we are executing commands) Copy the new generated admin.kubeconfig file to $HOME/.kube and edit it o update the ip address of server, make it the ip address of control plane instead of 127.0.01

Now run this commad
```
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/admin.kubeconfig
```

This is done to avoid typing the --kubeconfig=admin.kubeconfig while running kubectl commands on client machine.