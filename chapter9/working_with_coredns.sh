#!/bin/bash

cat > nettool.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
    name: ubuntu
spec:
    containers:
    - name: ubuntu
      image: ubuntu:latest
      command: [ "sleep" ]
      args: [ "infinity" ]
EOF

kubectl create -f nettool.yaml
kubectl exec -it ubuntu -- /bin/bash

# ---- inside ubuntu container ----
apt-get update; apt-get install curl dnsutils -y
dig # just run it 
cat /etc/resolv.conf # use the ip found here in below step (the nameserver)
dig -x 10.96.0.10 # find kube-dns.kube-system.svc.cluster.local.
curl service-lab.accounting.svc.cluster.local.
curl service-lab # this would fail
curl service-lab.accounting # this passes. Because ubunutu is in the default namespace, not accounting
exit

# ---- in vm ----
kubectl get svc -n kube-system kube-dns # note the IP patches the one in `/etc/resolv.conf`
kubectl get svc -n kube-system kube-dns -o yaml # inspect the output

kubectl get pod -l k8s-app -A # note all infra pods have this label

kubectl -n kube-system get pod coredns-787d4945fb-2zjvg -o yaml
kubectl -n kube-system get cm coredns -o yaml

kubectl -n kube-system edit cm coredns # add rewrite name regex (.*)\.test\.io {1}.default.svc.cluster.local
pod_name=$(kubectl get pod -o custom-columns=name:.metadata.name --no-headers | grep coredns)

# Create nginx
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=ClusterIP --port=80
kubectl get svc # note the ip of nginx: 10.102.126.40

kubectl exec -it ubuntu -- /bin/bash

# ---- inside ubuntu container ----
dig -x 10.102.126.40
dig nginx.default.svc.cluster.local.
# test the rewrite
dig nginx.test.io # ip should be same as above two
exit

# ---- in vm ----
kubectl -n kube-system edit cm coredns 
# rewrite stop { 
    # name regex (.*)\.test\.io {1}.default.svc.cluster.local
    # answer name (.*)\.default\.svc\.cluster\.local {1}.test.io
# }

# delete the coredns pods again
kubectl exec -it ubuntu -- /bin/bash

# ---- inside ubuntu container ----
dig nginx.test.io

# ---- on vm ----
kubectl delete -f nettool.yaml
