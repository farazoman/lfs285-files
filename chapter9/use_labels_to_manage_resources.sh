#!/bin/bash

kubectl delete pods -l system=secondary -A # deletes the pods
kubectl get pods -n accounting # pods should be recreated because they are managed by a deploy
kubectl get deploy -n accounting --show-labels
kubectl -n accounting delete deploy -l system=secondary
kubectl get pods -n accounting # verify pods are deleted (not being recreated)
 
kubectl label node ubu-wn system- # unlabel the worker noded