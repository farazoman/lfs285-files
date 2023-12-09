#!/bin/bash

# 1. create two deployments:
#   web-one -> runs httpd
#   web-two -> runs nginx
# 2. expose both as ClusterIPs

cat > web-one.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
    name: web-one
    labels:
        app: web-one
spec:
    selector:
        matchLabels:
            app: web-one
    replicas: 1
    template:
        metadata:
            labels:
                app: web-one
        spec:
            containers:
            - image: httpd:2.4.58
              imagePullPolicy: Always
              name: httpd
              ports:
              - containerPort: 80
EOF

cat > web-one-svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
    name: web-one-svc
spec:
    selector:
        app: web-one
    ports:
    - port: 80
      name: web  
    type: ClusterIP   
EOF

cat > web-two.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
    name: web-two
    labels:
        app: web-two
spec:
    replicas: 1
    selector:
        matchLabels:
            app: web-two
    template:
        metadata:
            labels:
                app: web-two
        spec:
            containers:
            - image: nginx:latest
              name: nginx
              ports:
              - containerPort: 8080       
EOF

cat > web-two-svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
    name: web-two-svc
spec:
    selector:
        app: web-two
    ports:
    - port: 80
      name: web
    type: ClusterIP
EOF

kubectl apply -f web-one.yaml
kubectl apply -f web-one-svc.yaml
kubectl apply -f web-two.yaml
kubectl apply -f web-two-svc.yaml

# 3. Install Ingress Controller with Helm
helm search hub ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm fetch ingress-nginx/ingress-nginx --untar
cd ingress-nginx

# update to DaemonSet; line ~180
vim vaules.yaml
helm install myingress .
kubectl get pod,svc
kubectl get ingress -A

# 4. Create an ingress manifest

cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: ingress-test
    annotations:
        nginx.ingress.kubernetes.io/service-upstream: "true"
    namespace: default
spec:
    ingressClassName: nginx
    rules:
    - host: www.external.com
      http:
        paths:
        - backend:
            service:
                name: web-one-svc
                port:
                    number: 80
          path: /
          pathType: ImplementationSpecific
EOF
kubectl apply -f ingress.yaml
kubectl get ing 
kubectl get pod -o wide
curl 192.168.222.151 # the nginx controller ip
curl 10.100.153.90 -H "Host: www.external.com"

# 5. Link to linkerd
kubectl get ds myingress-ingress-nginx-controller -o yaml \
 | linkerd inject --ingress - | kubectl apply -f -
for i in range {0..100}; do curl 10.100.153.90 -H "Host: www.external.com"
done
# view top in linkerd viz (on the browser)

kubectl exec -it web-two-7f76bd9dfb-j6n7q -- bash
# Inside nginx container
apt-get update && apt-get install vim -y
vim /usr/share/nginx/html/index.html # change something so it appears on curl
exit

kubectl edit ingress ingress-test # add new entry for two-svc, new host: 'internal.org'
curl 10.100.153.90 -H "Host: internal.org"

