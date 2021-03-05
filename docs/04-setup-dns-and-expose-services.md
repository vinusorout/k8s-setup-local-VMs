# Set up DNS and Kong

## CoreDNS
For DNS we will install CoreDNS, why kuernetes need DNS service, in kubernetes when we create any service then it assigns a DNS name to this service, the url will be in follwoing format:

<service_name>.<namespace>.svc.cluster.local:<service_port>

These urls can be accessed within a cluster i.e. in pod or controller manager etc not outside the cluster not even on control plane and worker nodes, To keep these records and DNS service, we will create the coredns using the yaml(scripts/addons/coredns.yaml.sed) file.

## Kong
Before moving forward let's see what are common types of services and what is an ingress:

**Services**
* ClusterIp : this type of service is use to expose any pod within the cluster and the DNS name for this will be in follwoing format <service_name>.<namespace>.svc.cluster.local:<service_port>

* LoadBalancer : on cloud providers we have external load balancers to redirect traffics to our cluster nodes, in our cluster we can create the load balancer service if it support load balancer services like in cloud.

* NodePort : this type of service is used to expose traffic using the port of the nodes, but we should not expose services on the node ports as for all the services you will have to specify the port number, and for end users it will be really bad.

**Ingress**
First of all it is not a service, to expose traffic to external world we need services not ingress, Ingress is used to route traffic within cluster based on routes to other services deployed in our cluster.


Kong is an ingress controller, and provides api-gateway/proxy which reroutes traffic as per the routes in url to different services as per the rules created by ingress object. Kong exposed an load balancer service, but as we dont have an external load balancer, we need to update this and use this as ClusterIP services.

Now we need to expose the kong-proxy service we will create a new deployment and service for nginx, and will expose the service on port 80(note while creating our clusters we used a posrt range from 1 to 32767, so we can expose this port 80). in nginx we will create a rule to redirect all the traffic to the kong proxy service.
```
http {
        upstream kong_gateway_proxy {
                server kong-proxy.kong.svc.cluster.local:80;
        }
        server {
                listen 80 default;
                server_name _;
                client_max_body_size 0;
                location / {
                    proxy_pass http://kong_gateway_proxy;
                    proxy_set_header Host $host;  
                    proxy_set_header x-nginx-hostname $hostname;  

                    proxy_connect_timeout      2m;
                    proxy_send_timeout         2m;
                    proxy_read_timeout         2m;
                    send_timeout               2m;
                }
        }
    }
```
Note the server url in nginx.conf file "kong-proxy.kong.svc.cluster.local:80", it is the DNS name of the kong-proxy service created in kong namespace. As within a cluster DNS name works fine, this will redirect all the traffic to kong-proxy service.

To set all this run [set-up-dns-kong-and-expose-to-world.sh](../scripts/addons/set-up-dns-kong-and-expose-to-world.sh)

## Testing
For testing purpose lets create httpbin service and deployment(yamls files are availabel in addons folder).

Run follwoing command:
```
kubectl apply -f httpbin.yaml
```

Create an ingress rule:
```
kubectl apply -f httpbin-ingress.yaml
```

Now open your browser and navigate to <worker_node_is>/httpbin
