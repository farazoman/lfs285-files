#!/bin/bash

cp rs.yaml ds.yaml
vim ds.yaml
# kind: DaemonSet
# name: ds-one
# REMOVE replicas: 2
# system: DaemonSetOne # edit both refs

kubectl create -f ds.yaml
kubectl get ds
kubectl get pod

kubectl describe pod \
 $(kubectl get pod -o json | jq -r '[.items[] | select(.metadata.name | startswith("ds-one"))][0].metadata.name')\
 | grep Image:
#     Image:          nginx:1.15.1

