crane-runner
============

This project is meant to help you migrate Kubernetes workloads from the comfort
of your own cloud by giving you the power of the crane command line tool in a
container, Tekton ClusterTasks, and Tekton Pipelines.

"How does it work?" you might ask. The ClusterTasks we provide work as a sort of
API contract, provide us with the input we need to run -- like the kubeconfig,
context, and namespace from the cluster you want to migrate workloads from in
the case of "export" -- and we handle the rest.

## Quick Start

No patience for documentation? All you need is cluster and Tekton to get
started.

See [Tekton's Getting Started](https://tekton.dev/docs/getting-started/) for how
to install Tekton.

Then run: `kustomize build github.com/djzager/crane-runner/manifests?ref=master`

## Getting Started

Check out [our Examples](./examples) to start working through your first
migration with crane-runner.
>>>>>>> d4db56d (docs: add readme)
