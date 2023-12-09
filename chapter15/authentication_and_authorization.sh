#!/bin/bash

# 1. Setup env and user
kubectl create ns development
kubectl create ns production

kubectl config get-contexts
sudo useradd -s /bin/bash DevDan
sudo passwd DevDan # pw is: lftr@in

openssl genrsa -out DevDan.key 2048

touch $HOME/.rnd
openssl req -new -key DevDan.key -out DevDan.csr -subj "/CN=DevDan/O=development"

sudo openssl x509 -req -in DevDan.cer \ # TODO is this .csr???
 -CA /etc/kubernetes/pki/ca.crt \
 -CAkey /etc/kubernetes/pki/ca.key \
 -CAcreateserial \
 -out DevDan.crt -days 100

# see difference between original and new configs
diff cluster-api-config .kube/config

# 2. Create a context
kubectl config set-context DevDan-context \
 --cluster=kubernetes \
 --namespace=development \
 --user=DevDan

kubectl --context=DevDan-context get pods # access should be restricted
kubectl config get-contexts
diff cluster-api-config .kube/config

# 3. Create a Role and associate RBAC to user

cat > role-dev.yaml << EOF
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
    namespace: development
    name: developer
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["deployments", "replicasets", "pods"]
  verbs: ["list", "get", "watch", "create", "update", "patch", "delete"]
EOF

kubectl create -f role-dev.yaml

cat > rolebind.yaml << EOF
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
    name: developer-role-binding
    namespace: development
subjects:
- kind: User
  name: DevDan
  apiGroup: ""
roleRef:
    kind: Role
    name: developer
    apiGroup: ""
EOF
kubectl create -f rolebind.yaml

kubectl --context=DevDan-context get pods # access should work
kubectl --context=DevDan-context create deploy nginx --image=nginx
kubectl --context=DevDan-context delete deploy nginx

# 4. Create different context for production systems
# view only permissions
cp role-dev.yaml role-prod.yaml
vim role-prod.yaml

cp rolebind.yaml rolebindprod.yaml
vim rolebindprod.yaml

kubectl apply -f role-prod.yaml
kubectl apply -f rolebindprod.yaml

kubectl config set-context ProdDan-context \
 --cluster=kubernetes \
 --namespace=production \
 --user=DevDan

kubectl --context=ProdDan-context get pods # works
kubectl --context=ProdDan-context create deploy nginx --image=nginx # should fail
kubectl -n production describe role dev-prod

# ???? how to create new users and assign them...