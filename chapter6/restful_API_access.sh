#!/bin/bash

server_endpoint_and_port=$(kubectl config view | yq '.clusters[0].cluster.server')
export token=$(kubectl create token default)

curl "$server_endpoint_and_port"/apis --header "Authorization: Bearer $token" -k
curl "$server_endpoint_and_port"/api/v1 --header "Authorization: Bearer $token" -k

#below should fail saying its forbidden
curl "$server_endpoint_and_port"/api/v1/namespaces --header "Authorization: Bearer $token" -k

kubectl run -i -t busybox --image=busybox --restart=Never

# this below token is the same as the token we generated above
cat /var/run/secrets/kubernetes.io/serviceaccount/token
