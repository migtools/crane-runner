**NOTE**

The reason this was moved to the graveyard was because it was not immediately
obvious how to make it so the "destination" cluster could communicate with the
"source" cluster.

It would be nice to be able to insert a kubect-convert step into a
pipeline to demonstrate the flexibiliy of handling deprecated APIs with crane
and other tools.

Migrating Deprecated APIs
============================

This tutorial shows you how to migrate deprecated Kubernetes API versions to
non-deprecated API versions using Crane Runner and kubectl-convert all in a
single Tekton Pipeline.

**NOTE**

This scenario is special in that it requires a very specific Kubernetes
version of the "source" cluster, one that supports Deployments with
`apps/v1beta2` apiVersion. To clean up:

```bash
curl -s "https://raw.githubusercontent.com/konveyor/crane/main/hack/minikube-clusters-delete.sh" | bash
```

# Roadmap

* Deploy Guestbook application in "source" cluster.
* Prepare for application mirror.
* Attempt to mirror application via Tekton PipelineRun. It will fail to apply
    because of unsupported API versions.
* Create [Tekton PipelineRun](https://tekton.dev/docs/pipelines/pipelineruns/)
    that includes kubectl-convert step to completely migrate the application.

# Before you begin

You will need a "source" and "destination" Kubernetes cluster with Tekton and
the Crane Runner ClusterTasks installed. The "source" cluster **MUST** be old
enough to support Deployments with `apps/v1beta2` apiVersion.

Below are the steps required for easy copy/paste:

```bash
# Start up "source" and "destination" clusters in minikube
curl -s "https://raw.githubusercontent.com/konveyor/crane/main/hack/minikube-clusters-start.sh" | SRC_KUBE_VERSION=1.15.12 bash

# Install Tekton
# See https://tekton.dev/docs/getting-started/ for help with installing Tekton
kubectl --context dest apply -f "https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml"
kubectl --context dest --namespace tekton-pipelines wait --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

# Install Crane Runner manifests
kustomize build github.com/konveyor/crane-runner/manifests | kubectl --context dest apply -f -
```

**NOTE**

It is imperitive that you have an older version of Kubernetes running in the
"source" cluster. Now is the time to check:

```bash
kubectl --context src version --short
```

You should find a "Server version" of `v1.15.12`.

# Deploy Guestbook application in "source" cluster

You will be deploying an outdated version of the
[Kubernetes' stateless guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
modified here to be consumable via kustomize.
The guestbook application consisists of:

* redis leader deployment and service
* redis follower deployment and service
* guestbook front-end deployment and service


```bash
kubectl --context src create namespace guestbook
kustomize build github.com/konveyor/crane-runner/examples/resources/guestbook-deprecated | kubectl --context src --namespace guestbook apply -f -
kubectl --context src --namespace guestbook wait --for=condition=ready pod --selector=app=guestbook --timeout=180s
```

**NOTE**

Notice that the `kustomize build` is referencing `guestbook-deprecated`.

# Prepare for Application Mirror

First, create the `guestbook` namespace in the "destination" cluster
where you will migrate the guestbook application from the "source" cluster.

```bash
kubectl --context dest create namespace guestbook
```

You must upload your kubeconfig as a secret. This will be used by the
ClusterTasks to migrate the application.
```bash
kubectl config view --flatten | kubectl --context dest --namespace guestbook create secret generic kubeconfig --from-file=config=/dev/stdin
```

Now that you have a namespace and kubeconfig, you need to reserve a
PersistentVolume to be used for data sharing.

```bash
cat <<EOF | kubectl --context dest --namespace guestbook create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: deprecated-apis-example
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
EOF
```

Lastly, verify the PersistentVolumeClaim is bound before proceeding.

```bash
$ kubectl --context dest --namespace guestbook get persistentvolumeclaims deprecated-apis-example
NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
deprecated-apis-example   Bound    pvc-8a692117-02a3-46e9-8a3a-43dade8f98d2   10Mi       RWO            standard       80s
```

# Attempt Application Mirror

```bash
kubectl --context dest --namespace guestbook create -f "https://raw.githubusercontent.com/konveyor/crane-runner/main/examples/004_handling-deprecated-APIs/pipelinerun.yaml"
```
