Stateless Application Mirror
============================

This tutorial shows you how to mirror a simple stateless
[PHP Guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
using Crane Runner and
[Tekton ClusterTasks](https://tekton.dev/docs/pipelines/tasks/#task-vs-clustertask).
Crane's export, transform, and apply functionality will be demonstrated through
executing [Tekton TaskRuns](https://github.com/tektoncd/pipeline/blob/main/docs/taskruns.md).

# Roadmap

* Deploy Guestbook application in "source" cluster.
* Prepare for application mirror.
* Run `crane-export` ClusterTask.
* Run `crane-transform` ClusterTask.
* Run `crane-apply` ClusterTask.
* Run `kubectl-apply-files` ClusterTask.

# Before You Begin

You will need a "source" and "destination" Kubernetes cluster with Tekton and
the Crane Runner ClusterTasks installed. Below are the steps required for easy
copy/paste:

```bash
# Start up "source" and "destination" clusters in minikube
curl -s "https://raw.githubusercontent.com/konveyor/crane/main/hack/minikube-clusters-start.sh" | bash

# Install Tekton
# See https://tekton.dev/docs/getting-started/ for help with installing Tekton
kubectl --context dest apply -f "https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml"
kubectl --context dest --namespace tekton-pipelines wait --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

# Install Crane Runner manifests
kubectl --context dest apply -k github.com/konveyor/crane-runner/manifests
```

# Deploy Guestbook Application in "source" Cluster

You will be deploying
[Kubernetes' stateless guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
modified here to be consumable via kustomize.
The guestbook application consisists of:

* redis leader deployment and service
* redis follower deployment and service
* guestbook front-end deployment and service


```bash
kubectl --context src create namespace guestbook
kubectl --context src --namespace guestbook apply -k github.com/konveyor/crane-runner/examples/resources/guestbook
kubectl --context src --namespace guestbook wait --for=condition=ready pod --selector=app=guestbook --timeout=180s
```

# Prepare for Application Mirror

First, you will create the `guestbook` namespace in the
"destination" cluster where workloads from the "source" cluster will be
mirrored.

```bash
kubectl --context dest create namespace guestbook
```

You will need to upload your kubeconfig -- with "source" and "destination"
cluster contexts included -- as a secret. This is how the mechanism through
which tasks will communicate with the "source" and "destination" clusters.


```bash
kubectl config view --flatten | kubectl --context dest --namespace guestbook create secret generic kubeconfig --from-file=config=/dev/stdin
```

Now that you have a namespace and kubeconfig, you will reserve a
PersistentVolume to be used for data sharing.

```bash
cat <<EOF | kubectl --context dest --namespace guestbook create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: stateless-app-mirror
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
EOF
```

Verify the PersistentVolumeClaim is bound before proceeding.

```bash
$ kubectl --context dest --namespace guestbook get persistentvolumeclaims stateless-app-mirror
NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
stateless-app-mirror   Bound    pvc-8a692117-02a3-46e9-8a3a-43dade8f98d2   10Mi       RWO            standard       80s
```

# Run `crane-export` ClusterTask

Crane's `export` command is how you extract all of the resources you want from
the "source" cluster.

```bash
cat <<EOF | kubectl --context dest --namespace guestbook create -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  generateName: stateless-app-mirror-export-
spec:
  params:
  - name: src-context
    value: src
  - name: src-namespace
    value: guestbook
  taskRef:
    name: crane-export
    kind: ClusterTask
  workspaces:
  - name: export
    persistentVolumeClaim:
      claimName: stateless-app-mirror
    subPath: export
  - name: kubeconfig
    secret:
      secretName: kubeconfig
EOF
```

# Run `crane-transform` ClusterTask

Crane's `transform` command helps you strip cluster specific information out of
the exported manifests by enumerating the modifications needed (ie. stripping
status information off of workloads) as JSON patches.

```bash
cat <<EOF | kubectl --context dest --namespace guestbook create -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  generateName: stateless-app-mirror-transform-
spec:
  taskRef:
    name: crane-transform
    kind: ClusterTask
  workspaces:
  - name: export
    persistentVolumeClaim:
      claimName: stateless-app-mirror
    subPath: export
  - name: transform
    persistentVolumeClaim:
      claimName: stateless-app-mirror
    subPath: transform
EOF
```

**NOTE**

If you look at the
[crane-transform ClusterTask](/manifests/clustertasks/crane-transform.yaml),
you will notice it can leverage a `craneconfig` workspace. If provided, you
could use it to configure crane's `transform` behavior.

An example configmap would look something like:

```
# IMPORTANT: DO NOT RUN - EXAMPLE
cat <<EOF | kubectl apply --namespace ${NAMESPACE} -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: craneconfig
data:
  config: |
    debug: false
    optional-flags:
      strip-default-pull-secrets: "true"
      registry-replacement: "docker-registry.default.svc:5000": "image-registry.openshift-image-registry.svc:5000"
      extra-whiteouts:
      - ImageStream.image.openshift.io
      - ImageStreamTag.image.openshift.io
      - StatefulSet.apps
      remove-annotations:
      - some-node-annotation
      - foobar
EOF
```


# Run `crane-apply` ClusterTask

Crane's `apply` command takes the exported resources + transformations saved as
JSON patches and renders the results as YAML files that you _should_ be able to
apply to another cluster as is. Should is an operative word here, if it doesn't
work, then the benefit of the non-destructive nature of crane is shown; you may
only need to change flags in the `transform` step re-`apply` and be finished.

Notice this task doesn't take any parameters, it simply takes the two input
directories (export and transform) and results are stored in apply directory.


```bash
cat <<EOF | kubectl --context dest --namespace guestbook create -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  generateName: stateless-app-mirror-apply-
spec:
  taskRef:
    name: crane-apply
    kind: ClusterTask
  workspaces:
  - name: export
    persistentVolumeClaim:
      claimName: stateless-app-mirror
    subPath: export
  - name: transform
    persistentVolumeClaim:
      claimName: stateless-app-mirror
    subPath: transform
  - name: apply
    persistentVolumeClaim:
      claimName: stateless-app-mirror
    subPath: apply
EOF
```

# Run `kubectl-apply` ClusterTask

This task is simple on purpose, it takes the results from the `apply` step (ie.
a directory of resources) and runs `kubectl apply` on them.

```bash
cat <<EOF | kubectl --context dest --namespace guestbook create -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  generateName: stateless-app-mirror-kubectl-apply-
spec:
  params:
  - name: dest-context
    value: dest
  taskRef:
    name: kubectl-apply-files
    kind: ClusterTask
  workspaces:
  - name: apply
    persistentVolumeClaim:
      claimName: stateless-app-mirror
    subPath: apply
  - name: kubeconfig
    secret:
      secretName: kubeconfig
EOF
```

# What's Next

* You could turn this collection of `TaskRun`s to a single `PipelineRun`.
* Check out [Stateless App Migration with Kustomize](../stateless-app-migration-with-kustomize/README.md)
* Read more about [Tekton](https://tekton.dev/docs/getting-started/)
* Read more about [Crane](https://github.com/konveyor/crane)

# Cleanup

```bash
kubectl --context dest delete namespace guestbook
```
