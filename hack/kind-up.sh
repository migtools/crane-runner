#!/usr/bin/env bash

set -ex

kind get clusters | grep -q src || cat <<EOF | kind create cluster --name src --wait 2m --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: 10.110.0.0/16
  serviceSubnet: 10.115.0.0/16
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8081
    protocol: TCP
  - containerPort: 443
    hostPort: 6443
    protocol: TCP
EOF
echo "src cluster up"

kind get clusters | grep -q dest || cat <<EOF | kind create cluster --name dest --wait 2m --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: 10.220.0.0/16
  serviceSubnet: 10.225.0.0/16
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8082
    protocol: TCP
  - containerPort: 443
    hostPort: 6444
    protocol: TCP
EOF
echo "dest cluster up"

# Ingress NGINX
for context in kind-src kind-dest; do
  kubectl --context ${context} apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
done
for context in kind-src kind-dest; do
  kubectl --context ${context} wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s
done
