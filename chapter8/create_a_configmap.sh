#!/bin/bash

# 1. create a config map with the primary colours
mkdir primary
echo c > primary/cyan
echo m > primary/magenta
echo y > primary/yellow
echo k > primary/black
echo "known as key" >> primary/black
echo "blue" > favourite

# 2. create a config map and populate it with the files afore-created
kubectl create configmap colors\
 --from-literal=text=black \
 --from-file=./favourite \
 --from-file=./primary/

kubectl get cm colors
kubectl get cm colors -o yaml # inspect shape of data

cat > simpleshell.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
    name: shell-demo
spec:
    containers:
    - name: nginx
      image: nginx
      env:
        - name: ilike
          valueFrom:
            configMapKeyRef:
                name: colors
                key: favourite
EOF

kubectl create -f simpleshell.yaml

kubectl get pod shell-demo -o yaml
kubectl exec shell-demo -- bash -c 'echo $ilike'
kubectl delete pod shell-demo


vim simpleshell.yaml
# change env to envFrom: - configMapRef: name: colors
kubectl create -f simpleshell.yaml
kubectl exec shell-demo -- bash -c 'printenv'
kubectl delete pod shell-demo

# Part 2
cat > car-map.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
    name: fast-car
    namespace: default
data:
    car.make: ford
    car.model: mustang
    car.trim: shelby
EOF
kubectl create -f car-map.yaml
kubectl get cm car-map.yaml -o yaml

cat > simpleshell.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
    name: shell-demo
spec:
    containers:
    - name: nginx
      image: nginx
      volumeMounts:
      - name: car-vol
        mountPath: /etc/cars
    volumes:
      - name: car-vol
        configMap:
            name: fast-car
EOF
# add volumeMount and volumes to map to the newly created configmap

kubectl delete pod shell-demo
kubectl create -f simpleshell.yaml

kubectl exec shell-demo -- bash -c 'df -ha | grep car'
kubectl exec shell-demo -- bash -c 'ls /etc/cars'
kubectl exec shell-demo -- bash -c 'cat /etc/cars/car.trim'

kubectl delete pod shell-demo
kubectl delete cm fast-car
kubectl delete cm colors