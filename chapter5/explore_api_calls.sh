#!/bin/bash

sudo apt-get install -y strace
strace kubectl get endpoints

cd /home/faraz/.kube/cache/discovery/
# explore the above dir, kubectl opens a lot of files here, as seen by the preceeding command
# view below in detail, shows the different verbs, shortnames of different k8s resources
cat apps/v1/serverresources.json  | jq

kubectl delete pod curlpod