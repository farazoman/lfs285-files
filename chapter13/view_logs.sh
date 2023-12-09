#!/bin/bash

# for systemd based clusters --- what are alternatives to systemd???
journalctl -u kubelet | less

sudo find / -name "*apiserver*log"

sudo less /var/log/containers/kube-apiserver-ubu-cp4_kube-system_kube-apiserver-6b222effe272ed944104110aba204b1a9d15f3c608182440cb75b541a37de868.log
# logs for other containers are found in that directory. Find can be used too if not easily found

# if not using systemd, logs can be found
# /var/log/kube-apiserver.log
# /var/log//kube-scheduler.lgo
# /var/log/kube-controller-manager.log
# /var/log/pods

# Worker node files
#/var/log/kubelet.log
#/var/log/kube-proxy.log

kubectl get pod -A
kubectl -n kube-system logs kube-apiserver-ubu-cp4