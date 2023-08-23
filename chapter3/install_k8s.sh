#!/bin/bash

# download course material and unzip
wget "https://training.linuxfoundation.org/cm/LFS258/LFS258_V2022-10-21_SOLUTIONS.tar.xz" \
 --user=LFtraining --password=Penguin2014
tar -xvf LFS258_V2022-10-21_SOLUTIONS.tar.xz SOLUTIONS.tar.xz

# enter Sudo Mode
sudo -i
# install dependent packages
apt-get update && apt-get upgrade -y
apt-get install -y vim # may already be installed if using ubuntu image
apt install curl apt-transport-https vim git wget gnupg2 \
     software-properties-common apt-transport-https ca-certificates uidmap -y

swapoff -a # needed for k8s if running locally

# create file
modprobe overlay
modprobe br_netfilter
cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# validate changes have been updated based on above
sysctl --system | grep -E "(table|forward)"

# ?
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
# https://forum.linuxfoundation.org/discussion/862825/kubeadm-init-error-cri-v1-runtime-api-is-not-implemented
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update -y
# workaround if error saying key can't be found; then run above again
# sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys <key_output_from_error>

apt install -y containerd.io
containerd config default | tee /etc/containerd/config.toml
sed -e's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
systemctl restart containerd
systemctl status containerd # make sure its running

# not sure what this is for
curl -s \
       https://packages.cloud.google.com/apt/doc/apt-key.gpg \
       | apt-key add -

# update based on the new repo added
apt-get update
apt-get install -y kubeadm=1.25.1-00 kubelet=1.25.1-00 kubectl=1.25.1-00
apt-mark hold kubelet kubeadm kubectl

# download calico CNI (networking) file 
wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
# old - curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml -O
# find calico cidr, paste in following steps for config file creation
# find IP (may be different, if so use hostname -i)
hostname -i
ip addr show
# add mapping of ip to machine name to `vim /etc/hosts` if not done 
 
cat << EOF | tee kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.25.0
controlPlaneEndpoint: "$(hostname):6443"
networking:
    podSubnet: 192.168.0.0/16
EOF

# Init CLUSTER!!!! (control plane)
kubeadm init --config=kubeadm-config.yaml --upload-certs \
    | tee kubeadm-init.out
 
# ERROR: 	[ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
# fix: 
    # root@ubu-20-cp:~# modprobe overlay
    # root@ubu-20-cp:~# modprobe br_netfilter
    # root@ubu-20-cp:~# systemctl restart containerd

# return to normal user
exit

# prep connecting to k8s server
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# verify its copied
less .kube/config
#NOTE verify that nodes are up and other useful things
# eg : kubectl get pods --all-namespaces

# set up networking plugin
sudo cp /root/calico.yaml .
 
# Optional
# sudo apt-get install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> $HOME/.bashrc

# GROW THE CLUSTER 3.2
# WORKER NODE (different VM)
sudo -i
apt-get update && apt-get upgrade -y
sudo apt install curl apt-transport-https vim git wget gnupg2 software-properties-common lsb-release ca-certificates uidmap -y

# Setup networking and install containerd
sudo swapoff -a
sudo modprobe overlay
sudo modprobe br_netfilter

cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update -y
apt install -y containerd.io
containerd config default | tee /etc/containerd/config.toml
sed -e's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
systemctl restart containerd
systemctl status containerd # make sure its running

# Install Kubernetes
echo "deb  http://apt.kubernetes.io/  kubernetes-xenial  main" >>/etc/apt/sources.list.d/kubernetes.list
#vim /etc/apt/sources.list.d/kubernetes.list  # this can probably use append, double check
# deb  http://apt.kubernetes.io/  kubernetes-xenial  main

curl -s \
       https://packages.cloud.google.com/apt/doc/apt-key.gpg \
       | apt-key add -

# update based on the new repo added

apt-get update && apt-get install -y kubeadm=1.25.1-00 kubelet=1.25.1-00 kubectl=1.25.1-00
apt-mark hold kubeadm kubelet kubectl

# CONTROL PLANE NODE
hostname -i
ip addr show | grep inet

openssl x509 -pubkey \
 -in /etc/kubernetes/pki/ca.crt | openssl rsa \
 -pubin -outform der 2>/dev/null | openssl dgst \
 -sha256 -hex | sed 's/^.* //'

# WORKER NODE
vim /etc/hosts
# add ip of CP to here with the name of the CP server

kubeadm join ubu-20-cp:6443\
    --token kedd9m.cw03ga67sqz5in1g\
    --discovery-token-ca-cert-hash sha256:12d9bf7061ad9605bf81cc4706d479148402af7afb8995de6d5894b31309f9c3


# 3.3 Finish Cluster Setup
# CONTROL PLANE
# remove taint so we can use CP for non-infra pods
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# make sure everything is up
kubectl get pods --all-namespaces
# if core dns is down, delete the pod so it respwans a new one
#verify if the tunl ip is present
ip a | grep tunl -A 3

# update critl config so containerd uses an updated config
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock

# 3.4 Deploy a Simple Application
# CONTROL PLANE
kubectl create deployment nginx --image=nginx
kubectl describe deployment nginx

kubectl get deployment nginx -o yaml > first.yaml
vim first.yaml

kubectl delete deployment nginx
kubectl create -f first.yaml
kubectl get deployment nginx -o yaml > second.yaml
diff first.yaml second.yaml
kubectl get deployment nginx -o json

vim first.yaml # add the ports info under the spec.spec for the given container
kubectl expose deployment/nginx
kubectl get svc nginx
kubectl get ep nginx
kubectl get pod -o wide # find out which node the pod is running on

# NODE that the pod is running on 
sudo tcpdump -i tunl0 # optionally run with '&' so you can still use that node


# else where
kubectl describe pod nginx-ff6774dc6-bmp97 | grep Node:
curl 192.168.81.132:80

kubectl scale deployment nginx --replicas=3

# 3.5 Access from outside the cluster
# CONTROL PLANE
kubectl exec nginx-ff6774dc6-wlxp6 -- printenv |grep KUBERNETES
kubectl delete svc nginx

# recreate the service with a load balancer type
kubectl expose deployment nginx --type=LoadBalancer
kubectl get svc
# update port forwarding to the exposed port retrieved from the output of svc

# Clean up
kubectl delete deployments nginx
kubectl delete ep nginx
kubectl delete svc nginx