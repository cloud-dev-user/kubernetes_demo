#/bin/bash 
# this script will install required packages and do required system configurations 

# adding host entries for k8s 
sudo hostnamectl set-hostname "k8sworker.ssktraining.com"
export master_hostname=`hostname -I`
export add_master_entry="$master_hostname k8sworker.ssktraining.com"
cat  hostname.txt | sudo tee -a /etc/hosts
#sudo -- sh -c -e "echo '$master_hostname k8smaster.ssktraining.com' >> /etc/hosts";

# disable swap 
sudo swapoff -a 
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system


# install containerd runtime


sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


sudo apt update
sudo apt install -y containerd.io

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml


sudo systemctl restart containerd
sudo systemctl enable containerd

# Add kubernetes repository

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/kubernetes-xenial.gpg

sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

# install Kubectl , Kubeadm and kubelet 

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


# Initiate kubernetes Cluster, Create Master 
#sudo kubeadm init --control-plane-endpoint=k8smaster.ssktraining.com




