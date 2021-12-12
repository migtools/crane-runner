Crane Runner
============

This project is meant to help you migrate Kubernetes workloads from the comfort
of your own cloud by giving you the power of the crane command line tool in a
container, Tekton ClusterTasks, and Tekton Pipelines.

"How does it work?" you might ask. The ClusterTasks we provide work as a sort of
contract, provide us with the input we need to run -- like the kubeconfig,
context, and namespace from the cluster you want to migrate workloads from in
the case of "export" -- and we handle the rest.

## Quick Start

No patience for documentation? All you need is a cluster and Tekton to get
started.


```shell
# See https://tekton.dev/docs/getting-started/ for help with installing Tekton
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# Wait for Tekton to be ready
kubectl --namespace tekton-pipelines wait --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s
```

Now install our Tekton related manifests:

```shell
kustomize build github.com/konveyor/crane-runner/manifests | kubectl apply -f -
```

## Getting Started

Check out [our Examples](./examples) to start working through your first
migration with Crane.
