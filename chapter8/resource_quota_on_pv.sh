#!/bin/bash

# 1. Clean up from previous steps
kubectl delete deploy nginx-nfs
kubectl delete pvc pvc-1
kubectl delete pv pvvol-1

# 2. Prep ENV and files
cat > storage_quota.yml << EOF
apiVersion: v1
kind: ResourceQuota
metadata:
    name: storagequota
spec:
    hard: 
        persistentvolumeclaims: "10"
        requests.storage: "500Mi"
EOF

kubectl create namespace small
kubectl describe ns small # note, no quotas

# 3. Apply manifests
kubectl apply -n small -f PVol.yaml
kubectl apply -n small -f pvc.yaml
kubectl apply -n small -f storage_quota.yml

kubectl describe ns small

updated=$(sed '/namespace/d' nfs-pod.yaml) && echo "$updated" > nfs-pod.yaml # not tested, but should remove the namespace line in the manifest
kubectl apply -n small -f nfs-pod.yaml
kubectl get deploy -n small
kubectl get pod -n small

# 4. Validate its been mounted properly
pod_name=$(kubectl get pod -n small -o custom-columns=name:.metadata.name --no-headers | head -n 1)
kubectl exec -n small $pod_name -- bash -c "ls -l /opt"
kubectl exec -n small $pod_name -- bash -c "cat /opt/hello.txt"

# 5. Create additional volumes and prepare for the quota testing
kubectl describe ns small
du -h /opt/
sudo dd if=/dev/zero of=/opt/sfw/bigfile bs=1M count=300
du -h /opt/
kubectl describe ns small

kubectl delete deploy -n small nginx-nfs
kubectl delete pvc pvc-1 -n small
kubectl describe ns small

# 6. Test out Reclaim Policy
kubectl patch pv pvvol-1 -p '{"spec": {"persistentVolumeReclaimPolicy": "Delete"}}'
kubectl get pv
kubectl describe ns small
kubectl apply -n small -f pvc.yaml
kubectl describe ns small

# 7. Delete Quota and reduce it to a lower value
kubectl delete -n small storagequota
kubectl apply -n small -f storage_quota.yaml

kubectl apply -f nfs-pod.yaml -n small # note no errors are seen, only enforced if there is also a limit range

# delete should fail on PV

# 8. Recycle Policy, Block Deployment
vim PVol.yaml # update the reclaim policy
kubectl apply -n small -f low-resource-range.yaml # the file contents are in other sh file search LimitRange
kubectl describe ns small
kubectl apply -n small -f pvc.yaml # should fail due to quota being enforced

kubectl edit -n small resourcequota storagequota # update limit to 500mi
kubectl apply -f nfs-pod.yaml -n small # note no errors are seen, only enforced if there is also a limit range

# 9. Cleanup