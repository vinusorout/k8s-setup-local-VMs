#!/bin/bash

kubectl_file=/usr/local/bin/kubectl

if [ -f "$kubectl_file" ]; then
    echo "$kubectl_file exists."
else 
    echo "$kubectl_file does not exist."
    wget https://storage.googleapis.com/kubernetes-release/release/v1.20.4/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin
fi