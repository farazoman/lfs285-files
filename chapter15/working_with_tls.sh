#!/bin/bash

# 1. explore the configurations and base layer
# find the security info such as auth mode
systemctl status kubelet
sudo less /var/lib/kubelet/config.yaml # has mode webhook
sudo ls /etc/kubernetes/manifests
sudo less /etc/kubernetes/manifests/kube-controller-manager.yaml

kubectl -n kube-system get secrets # steps say to look at bootstrap token. Doesn't exist for me
kubectl config view
kubectl config set-credentials -h

cp $HOME/.kube/config $HOME/cluster-api-config

sudo kubeadm token -h
sudo kubeadm config -h

sudo kubeadm config print init-defaults

