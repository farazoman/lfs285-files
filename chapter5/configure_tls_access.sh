#!/bin/bash



cert_auth_data=$(yq '.clusters[0].cluster.certificate-authority-data' < ~/.kube/config)
client_key_data=$(yq '.users[0].user.client-key-data' < ~/.kube/config)
client_cert_data=$(yq '.users[0].user.client-certificate-data' < ~/.kube/config)

echo "$client_cert_data" | base64 -d - > ./client.pem
echo "$client_key_data" | base64 -d - > ./client-key.pem
echo "$cert_auth_data" | base64 -d - > ./ca.pem

server_url=$(yq '.clusters[0].cluster.server' < ~/.kube/config)

curl --cert ./client.pem \
 --key ./client-key.pem \
 --cacert ./ca.pem \
 "$server_url"/api/v1/pods

cat > curlpod.json << EOF
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "curlpod",
    "namespace": "default",
    "labels": {
      "name": "examplepod"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "nginx",
        "image": "nginx",
        "ports": [
          {
            "containerPort": 80
          }
        ]
      }
    ]
  }
}
EOF

curl --cert ./client.pem \
  --key ./client-key.pem --cacert ./ca.pem \
  "$server_url"/api/v1/namespaces/default/pods \
  -XPOST -H'Content-Type: application/json'\
  -d@curlpod.json