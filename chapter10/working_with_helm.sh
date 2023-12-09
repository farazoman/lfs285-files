#!/bin/bash

# Install Helm
wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
tar -xvf helm-v3.12.0-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/helm

helm search hub database # check helm is installed successfully

# Add repos and install Tester tool
helm repo add ealenn https://ealenn.github.io/charts
helm repo update
helm upgrade -i tester ealenn/echo-server --debug

kubectl get svc
# curl the ip of the tester service
curl 10.104.105.100

helm list # see what you've installed with helm

# Uninstall Tester tool
helm uninstall tester
helm list

# See the tester tool chart
find $HOME -name *echo*

cd /home/faraz/.cache/helm/repository
tar -xvf echo-server-*
# explore in the folder

# Add another repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm fetch bitnami/apache --untar
cd apache/
less values.yaml # explore the values
kubectl get svc
# curl the ip
curl 10.111.115.220

# chart deployment output tells us about missing dependencies ??? from quiz

