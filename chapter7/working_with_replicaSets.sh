#!/bin/bash

# view existing RS
kubectl get rs

cat > rs.yaml << EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
    name: rs-one
spec:
    replicas: 2
    selector:
        matchLabels:
            system: ReplicaOne
    template:
        metadata:
            labels:
                system: ReplicaOne
        spec:
            containers:
                - name: nginx
                  image: nginx:1.15.1
                  ports:
                  - containerPort: 80
EOF

kubectl create -f rs.yaml
kubectl describe rs rs-one
kubectl get pods
kubectl delete rs rs-one --cascade=orphan # does delete the pods
kubectl get pods
kubectl get rs

# Create the RS again and it should take control of the existing pods
kubectl create -f rs.yaml
kubectl get rs

# Isolate a pod from its RS
kubectl edit pod "$(kubectl get pod -o json | jq -r '.items[0].metadata.name')"
sleep 4 && kubectl get pods # should see 3 pods as the rs needs to create a new one
kubectl get rs
kubectl get pod -L system # shows label values as well

kubectl delete rs rs-one
kubectl get pods # one should remain
kubectl get rs # should be empty

# cleanup pod
kubectl delete pod "$(kubectl get pod -o json | jq -r '.items[0].metadata.name')"