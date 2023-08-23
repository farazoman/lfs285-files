#!/bin/bash

kubectl get deploy webserver -o yaml | grep -A 4 strategy

kubectl edit deploy webserver 
# remove rollingUpdate object + update type to Recreate

# update the image to see the effects of the prior update
kubectl set image deploy webserver nginx=nginx:1.23.1-alpine

#view changes
kubectl describe pod \
 $(kubectl get pod -o json | jq -r '[.items[] | select(.metadata.name | startswith("webserver"))][0].metadata.name')\
 | grep Image:
kubectl rollout history deploy webserver
kubectl rollout history deploy webserver --revision=1

# Undo above
kubectl rollout undo deploy webserver