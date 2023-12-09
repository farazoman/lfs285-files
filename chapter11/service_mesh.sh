#!/bin/bash

# 1. Install LinkerD
curl -sL run.linkerd.io/install | sh
export PATH=$PATH:/home/faraz/.linkerd2/bin
echo $PATH >> $HOME/.bashrc

linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check
linkerd viz install | kubectl apply -f -
linkerd viz check
linkerd viz dashboard &

# 2. Expose dashboard
# edit the service and update the type to NodePort (expose the container port to the node)
kubectl edit -n linkerd svc web
# this exposes the port globally
# on local, update port forwarding to access the new port
# on web browser go to that ip:port
kubectl create -f nginx-one.yaml -n accounting

# for linkerd to monitor a pod, it needs a label
kubectl -n accounting get deploy nginx-one -o yaml\
 | linkerd inject - | kubectl apply -f -
# curl nginx-one many  times
kubectl -n accounting scale deploy nginx-one --replicas=5
# curl nginx-one many  times
