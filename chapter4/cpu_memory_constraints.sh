#!/bin/bash

kubectl config set-context --current --namespace=default
kubectl create deployment hog --image vish/stress
kubectl get deployments

kubectl describe deployment hog
kubectl get deployment hog -o yaml
kubectl get deployment hog -o yaml > hog.yaml

#add memory limits
# resources:
#     limits:                     
#         memory: "4Gi"
#     requests:
#         memory: "2500Mi"
vim hog.yaml
kubectl replace -f hog.yaml
kubectl describe deployment hog

# get logs of hog
# inspect the memory
kubectl logs "$(kubectl get pod | grep Running | grep -e 'hog-[^\ ]*' -o)"

# update hog to set resources to consume
# resources: ...
# args:
# - -cpus
# - "2"
# - -mem-total
# - "950Mi"
# - -mem-alloc-size
# - "100Mi"
# - -mem-alloc-sleep
# - "1s"
vim hog.yaml

kubectl delete deployment hog
# observe top for changes
kubectl create -f hog.yaml