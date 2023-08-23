#!/bin/bash

# view current update strategy
kubectl get ds ds-one -o yaml | grep -A 4 Strategy
kubectl edit ds ds-one # remove maxSurge and change type to OnDelete
# NOTE: OnDelete means you need to manually delete the image

# update image of ds
kubectl set image ds ds-one nginx=nginx:1.16.1-alpine
# verify the image of the previous section is unchanged

kubectl describe pod \
 $(kubectl get pod -o json | jq -r '[.items[] | select(.metadata.name | startswith("ds-one"))][0].metadata.name')\
 | grep Image:
 # Unchanged!!!

# delete the old pod 
kubectl delete pod \
 $(kubectl get pod -o json | jq -r '[.items[] | select(.metadata.name | startswith("ds-one"))][0].metadata.name')

kubectl rollout history ds ds-one

# see all reivisions to see the full history
kubectl rollout history ds ds-one --revision=4

kubectl rollout undo ds ds-one --to-revision=3
# the above won't change the pods, VERIFY! verified ;)

# verify the ds was updated
kubectl describe ds | grep Image:

# create a new DS with rolling update policy
kubectl get ds ds-one -o yaml  > ds2.yaml
vim ds2.yaml
kubectl create -f ds2.yaml

kubectl get pod
kubectl get ds

kubectl describe pod \
 $(kubectl get pod -o json | jq -r '[.items[] | select(.metadata.name | startswith("ds-two"))][0].metadata.name')\
 | grep Image:

kubectl edit ds ds-two # update image to .16
kubectl get ds

kubectl describe pod \
 $(kubectl get pod -o json | jq -r '[.items[] | select(.metadata.name | startswith("ds-two"))][0].metadata.name')\
 | grep Image:

kubectl rollout history ds ds-two
kubectl rollout undo ds ds-two 

kubectl delete ds ds-one
kubectl delete ds ds-two