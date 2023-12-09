#!/bin/bash

# 0. Sanity
kubectl get nodes # should be in ready state
kubectl describe nodes | grep -A5 -i label # view current labels and taints
kubectl describe nodes | grep -i taint

kubectl get deploy -A
sudo crictl ps | wc -l # 30 on cp
sudo crictl ps | wc -l # on worker node; failed for some reason
kubectl get pod -A | wc -l # 29 on cp

# 1. Label node(s)
kubectl label nodes ubu-cp4 status=vip
kubectl label nodes ubu-wn status=other
kubectl get nodes --show-labels

# 2. Setup and test labels
cat > vip.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
    name: vip
spec:
    nodeSelector:
        status: vip
    containers:
    - name: vip1
      image: busybox
      args:
      - sleep
      - "1000000"
    - name: vip2
      image: busybox
      args:
      - sleep
      - "1000000"
    - name: vip3
      image: busybox
      args:
      - sleep
      - "1000000"
    - name: vip4
      image: busybox
      args:
      - sleep
      - "1000000"
EOF
kubectl apply -f vip.yaml


sudo cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///var/run/dockershim.sock
timeout: 10
debug: false
EOF

sudo crictl ps | wc -l # 33 on cp
kubectl get pod -A | wc -l # 30 on cp
sudo crictl ps | wc -l # on worker node; failed for some reason

kubectl delete pod vip
vim vip.yaml # comment out the nodeSelector
kubectl apply -f vip.yaml
# this pod can go to either node

cp vip.yaml other.yaml
sed -i s/vip/other/g other.yaml
vim other.yaml # uncomment the selector

kubectl apply -f other.yaml

# 4 cleanup
kubectl delete pod other vip