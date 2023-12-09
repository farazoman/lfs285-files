#!/bin/bash

# 1. Deploy first instance of deployment
cat > taint.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
    name: taint-deployment
spec:
    replicas: 8
    selector:
        matchLabels:
            app: nginx
    template:
        metadata:
            labels:
                app: nginx
        spec:
            containers:
            - name: nginx
              image: nginx:1.20.1
              ports:
              - containerPort: 80
EOF

# see that the pods are deployed across the nodes
kubectl apply -f taint.yaml
kubectl get pod -o wide
sudo crictl ps | wc -l
sudo crictl ps | grep nginx

kubectl delete deployment taint-deployment
kubectl get pod

# 2. Use a taint: PreferNoSchedule
kubectl taint nodes ubu-wn bubba=value:PreferNoSchedule
kubectl describe node | grep Taint

kubectl apply -f taint.yaml

# see that the pods are deployed only on the CP
kubectl apply -f taint.yaml
kubectl get pod -o wide
sudo crictl ps | wc -l

kubectl delete deployment taint-deployment
kubectl get pod

# Remove the taint
kubectl taint nodes ubu-wn bubba-
kubectl describe node | grep Taint

kubectl apply -f taint.yaml

# 3. Use NoSchedule taint
kubectl taint nodes ubu-wn bubba=value:NoExecute
kubectl get pod -o wide # pods should be getting deleted and recreated on the other node (cp)
kubectl taint nodes ubu-wn bubba-
kubectl get pod -o wide 

# 4. cleanup
kubectl delete deployment taint-deployment
