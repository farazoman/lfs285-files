#!/bin/bash

# 1. Create a CRD
kubectl get crd -A
less calico.yaml
kubectl describe crd bgppeers.crd.projectcalico.org

cat > crd.yaml << EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
    name: crontabs.stable.example.com # name must match below
spec:    
    group: stable.example.com
    versions:
    - name: v1
      served: true # enable or disable a version
      storage: true # one and only one version must be marked as the storage version
      schema:
        openAPIV3Schema:
            type: object
            properties:
                spec:
                    type: object
                    properties:
                        cronSpec:
                            type: string
                        image:
                            type: string
                        replicas:
                            type: integer
    scope: Namespaced
    names:
        plural: crontabs
        singular: crontab
        kind: CronTab
        shortNames:
        - ct
EOF
kubectl create -f crd.yaml

kubectl get crd | grep cron

# 2. Create a custom object

cat > new-crontab.yaml << EOF
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
    name: new-cron-object
spec:
    cronSpec: "*/5 * * * *"
    image: some-cron-image # dns
EOF

kubectl apply -f new-crontab.yaml

kubectl get ct
kubectl describe ct

kubectl delete -f crd.yaml