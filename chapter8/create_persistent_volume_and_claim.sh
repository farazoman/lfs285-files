#!/bin/bash

# 1. on CP node. Install NFS
sudo apt-get update && sudo apt-get install -y nfs-kernel-server

# 2. make a dir to be shared, give similar permissions to /tmp

sudo mkdir /opt/sfw
sudo chmod 1777 /opt/sfw
# note, the below with quotes does it on  bash, without on local system (there are nuances but generally)
sudo bash -c 'echo software > /opt/sfw/hello.txt'

# 3. edit the NFS server file to share out the newly created directory
sudo bash -c 'echo "/opt/sfw/ *(rw,sync,no_root_squash,subtree_check)" >> /etc/exports' # shared with ALL
sudo exportfs -ra # reload exports

# ON WORKER NODE
# Install NFS Common & Mount Shared Vol
sudo apt-get -y install nfs-common
showmount -e ubu-20-cp
sudo mount ubu-20-cp:/opt/sfw /mnt
ls -l /mnt/


# BACK TO CP Node
cat > PVol.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
    name: pvvol-1
spec:
    capacity:
        storage: 200Mi
    accessModes:
        - ReadWriteMany # note this is presently informational, NOT enforced
    persistentVolumeReclaimPolicy: Retain # Delete, Recycle are other options - delete will delete the api object + the storage. Recycle cleans storage and keeps the api object - to be deprecated with intro of dynamic provisioning
    nfs:
        path: /opt/sfw
        server: ubu-20-cp
        readOnly: false
EOF
kubectl apply -f PVol.yaml

kubectl get pv
kubectl get pv pvvol-1 -o yaml

# PERSISTENT VOLUME CLAIM
# sanity
kubectl get pvc

cat > pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pvc-1
spec:
    accessModes:
        - ReadWriteMany
    resources:
        requests:
            storage: 100Mi
EOF
kubectl apply -f pvc.yaml

# Create a deployment which uses the claim
cp first.yaml nfs-pod.yaml
vim nfs-pod.yaml
# Edit the fields to the following values, or add if non-existent
#   name: nginx-nfs
#         volumeMounts:
#             - name: nfs-vol
#               mountPath: /opt
#       volumes:
#         - name: nfs-vol
#           persistentVolumeClaim:
#               claimName: pvc-1

kubectl apply -f nfs-pod.yaml

# Verify the hello.txt file is at expected location (i.e the volume is actually mounted)
pod_name=$(kubectl get pod -o custom-columns=name:.metadata.name --no-headers | head -n 1)
kubectl exec $pod_name -- bash -c "ls -l /opt"
kubectl exec $pod_name -- bash -c "cat /opt/hello.txt"

# pvc should still be bound
kubectl get pvc