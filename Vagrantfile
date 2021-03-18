# -*- mode: ruby -*-
# vi: set ft=ruby :
NUM_MASTER_NODE = 1
NUM_WORKER_NODE = 1

IP_NW = "192.168.2."
MASTER_IP_START = 50
MASTER_PORT_START = 2710 
NODE_IP_START = 70
NODE_PORT_START = 2720
CLIENT_IP_START = 60
CLIENT_PORT_START = 2730
LB_IP_START = 80

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/bionic64"
  config.vm.box_check_update = false

  (1..NUM_MASTER_NODE).each do |i|
    config.vm.define "kmaster-#{i}" do |node|
      # Name shown in the GUI
      node.vm.provider "virtualbox" do |vb|
        vb.name = "k-master-#{i}"
        vb.memory = 2048
        vb.cpus = 2
      end
      node.vm.hostname = "kmaster-#{i}"
      node.vm.network :private_network, ip: IP_NW + "#{MASTER_IP_START + i}"
      #node.vm.network "public_network", :type => "bridge" , :dev => "br0", :mode => "bridge"
      node.vm.network "forwarded_port", guest: 22, host: "#{MASTER_PORT_START + i}"
      config.vm.synced_folder "C:/Users/vinay/Desktop/k8s-bare-metal/k8s", "/vagrant_data"

      node.vm.provision "shell", inline: <<-SHELL
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
        systemctl restart sshd.service

        sed -i 's/RANDFILE/#RANDFILE/' /etc/ssl/openssl.cnf

        set -e
        IFNAME="enp0s8"
        ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
        sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts
        sed -e '/^.*ubuntu-bionic.*/d' -i /etc/hosts
      SHELL

      node.vm.provision "update-hosts", :type => "shell", :path => "update-hosts.sh"

    end
  end

  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "kworker-#{i}" do |node|
      # Name shown in the GUI
      node.vm.provider "virtualbox" do |vb|
        vb.name = "k-worker-#{i}"
        vb.memory = 2048
        vb.cpus = 2
      end
      node.vm.hostname = "kworker-#{i}"
      node.vm.network :private_network, ip: IP_NW + "#{NODE_IP_START + i}"
      #node.vm.network "public_network", :type => "bridge" , :dev => "br0", :mode => "bridge"
      node.vm.network "forwarded_port", guest: 22, host: "#{NODE_PORT_START + i}"
      config.vm.synced_folder "C:/Users/vinay/Desktop/k8s-bare-metal/k8s", "/vagrant_data"

      node.vm.provision "shell", inline: <<-SHELL
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
        systemctl restart sshd.service

        sed -i 's/RANDFILE/#RANDFILE/' /etc/ssl/openssl.cnf

        set -e
        IFNAME="enp0s8"
        ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
        sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts
        sed -e '/^.*ubuntu-bionic.*/d' -i /etc/hosts

        sudo apt-get -y install socat conntrack ipset
        sudo swapoff -a
      SHELL

      node.vm.provision "update-hosts", :type => "shell", :path => "update-hosts.sh"

    end
  end

  # kclient machine
  config.vm.define "kclient" do |node|
    # Name shown in the GUI
    node.vm.provider "virtualbox" do |vb|
      vb.name = "k-client"
      vb.memory = 512
      vb.cpus = 1
    end
    node.vm.hostname = "kclient"
    node.vm.network :private_network, ip: IP_NW + "#{CLIENT_IP_START + 1}"
    #node.vm.network "public_network", :type => "bridge" , :dev => "br0", :mode => "bridge"
    node.vm.network "forwarded_port", guest: 22, host: "#{CLIENT_PORT_START + 1}"
    config.vm.synced_folder "C:/Users/vinay/Desktop/k8s-bare-metal/k8s", "/vagrant_data"

    node.vm.provision "shell", inline: <<-SHELL
      sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
      systemctl restart sshd.service

      sed -i 's/RANDFILE/#RANDFILE/' /etc/ssl/openssl.cnf

      set -e
      IFNAME="enp0s8"
      ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
      sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts
      sed -e '/^.*ubuntu-bionic.*/d' -i /etc/hosts
    SHELL

    node.vm.provision "update-hosts", :type => "shell", :path => "update-hosts.sh"

  end

end
