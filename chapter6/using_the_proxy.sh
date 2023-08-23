#!/bin/bash

# review the help of the proxy tool
kubectl proxy -h

#Creates a proxy server or application-level gateway between localhost and the Kubernetes API server. It also allows
#serving static content over specified HTTP path. All incoming data enters through one port and gets forwarded to the
#remote Kubernetes API server port, except for the path matching the static content path.

kubectl proxy --api-prefix=/ & # <- runs remotely, record the pid (line below)
proxy_pid=$!

curl http://127.0.0.1:8001/api/
curl http://127.0.0.1:8001/api/v1
curl http://127.0.0.1:8001/api/v1/namespaces

kill $proxy_pid