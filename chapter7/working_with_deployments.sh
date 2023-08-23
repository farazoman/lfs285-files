#!/bin/bash

kubectl create deploy webserver --image nginx:1.22.1 --replicas=2 --dry-run=client -o yaml | tee dep.yaml
kubectl create -f dep.yaml
kubectl get deploy
kubectl get pod

kubectl describe pod \
 $(kubectl get pod -o json | jq -r '[.items[] | select(.metadata.name | startswith("webserver"))][0].metadata.name')\
 | grep Image:
