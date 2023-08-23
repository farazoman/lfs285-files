#!/bin/bash

#Create a job which will run a container which sleeps for three seconds then stops
cat > job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
    name: sleepy
spec: 
    template:
        spec:
            containers:
            - name: resting
              image: busybox
              command: ["/bin/sleep"]
              args: ["3"]
            restartPolicy: Never
EOF

kubectl create -f job.yaml
kubectl get job
kubectl get jobs.batch sleepy -o yaml

# cleanup, only affects "AGE"
kubectl delete jobs.batch sleepy

cp job.yaml job_custom.yaml
vim job_custom.yaml # add spec.completions: 5
kubectl apply -f  job_custom.yaml

kubectl get pods #only one pod should appear at a time
kubectl get pods --watch # to see the pods the job creates

# cleanup, only affects "AGE"
kubectl delete jobs.batch sleepy


vim job_custom.yaml # add spec.parallelism: 2
kubectl apply -f  job_custom.yaml

kubectl get pods # two pods will be observed in parallel
vim job_custom.yaml # add spec.activeDeadlineSeconds: 15, + increase sleep to 5
kubectl get jobs.batch sleepy -o yaml # view detail

# cleanup, only affects "AGE"
kubectl delete jobs.batch sleepy

### CREATE CRONJOB
cp job.yaml cronjob.yaml
vim cronjob.yaml 
# add spec.schedule:"*/2 * * * *"
# change kind to CronJob
# add spec.jobTemplate.spec: <existing job json>

kubectl apply -f cronjob.yaml
kubectl get cronjobs.batch
kubectl get jobs.batch

kubectl delete cronjob sleepy

vim cronjob.yaml # add spec.activeDeadlineSeconds: 10, sleep to 30, cron timer to 1 min for faster testing
kubectl apply -f cronjob.yaml
# wait 2-3 mins
kubectl get cronjob.batch
kubectl get jobs.batch

kubectl delete cronjob sleepy
