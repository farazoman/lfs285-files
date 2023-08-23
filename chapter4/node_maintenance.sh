#!/bin/bash

sudo grep data-dir /etc/kubernetes/manifests/etcd.yaml

# exec into the etcd pod
cd /etc/kubernetes/pki/etcd
# note: `ls` or `find` both don't work
exit
# for some reason you can't run etcdctl commands without setting the env vars
kubectl -n kube-system exec -it etcd-ubu-20-cp -- sh \
 -c "ETCDCTL_API=3 \  #Version to use
 ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
 ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
 ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
 etcdctl endpoint health"

kubectl -n kube-system exec -it etcd-ubu-20-cp -- sh \
 -c "ETCDCTL_API=3 \
 ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
 ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
 ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
 etcdctl member list"
# use `-w table` to output the info in a table

# backup
# run `etcdctl --endpoints=https://127.0.0.1:2379 snapshot save /var/lib/etcd/snapshot.db` with above vars
# confirm the backup exists on the VM

# Back up other important info
mkdir $HOME/backup1
sudo cp /var/lib/etcd/snapshot.db $HOME/backup/snapshot.db-$(date +%m-%d-%y)
sudo cp /root/kubeadm-config.yaml $HOME/backup/
sudo cp -r /etc/kubernetes/pki/etcd $HOME/backup/

# update kubeadm
sudo apt update
sudo apt-cache madison kubeadm # view available packages
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.26.1-00
sudo apt-mark hold kubeadm

# upgrade the cluster
kubectl drain ubu-20-cp --ignore-daemonsets
sudo kubeadm upgrade plan       ˚??????JX>cx
# the plan might say to update kubeadm
sudo apt-get install -y kubeadm=1.26.4-00
sudo kubeadm upgrade apply v1.26.4 | tee upgrade_to_1.26.4.log

# upgrade kubelet | run kubectl get node to see old version
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.26.1-00 kubectl=1.26.1-00
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet
# kubectl get node to see version has bee updated

kubectl uncordon ubu-20-cp

# do same on worker node
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.26.1-00
sudo apt-mark hold kubeadm

kubectl drain ubu-20-wn --ignore-daemonsets
sudo kubeadm upgrade node

sudo systemctl daemon-reload
sudo systemctl restart kubelet

kubectl uncordon ubu-20-wn