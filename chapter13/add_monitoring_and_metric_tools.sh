#!/bin/bash

git clone https://github.com/kubernetes-incubator/metrics-server.git

cd metrics-server/ ; less README.md
kubectl create -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system get pods # may be running but not ready
kubectl -n kube-system edit deployment metrics-server # add insecure TLS - should fix the "readiness" problem

kubectl -n kube-system logs metrics-server<TAB>

# Test the metrics server is working 
kubectl top pod -A
kubectl top ndoes

# instructions to install kube dash is here
# use helm and change service type to NodePort

