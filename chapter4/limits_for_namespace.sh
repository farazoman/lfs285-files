#/bin/bash

kubectl create namespace low-usage-limit
kubectl get namespace

cat > low-resource-range.yaml << EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: low-resource-range
spec:
  limits:
    - default:
        cpu: 1
        memory: 500Mi
      defaultRequest:
        cpu: 0.5
        memory: 100Mi
      type: Container
EOF

kubectl --namespace=low-usage-limit create -f low-resource-range.yaml

kubectl get LimitRange --all-namespaces

kubectl -n low-usage-limit create deployment limited-hog --image vish/stress
kubectl get deployments --all-namespaces
kubectl -n low-usage-limit get pods
kubectl -n low-usage-limit get pod limited-hog-5b6647ff5c-lr8sm -o yaml

# lets make a container to meet the namespace limits
cp hog.yaml hog1.yml
vim hog1.yml # update namespace to low-usage-limit
kubectl create -f hog1.yml

kubectl -n low-usage-limit delete deployment hog