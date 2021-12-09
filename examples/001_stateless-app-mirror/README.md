Stateless Application Mirror
============================

This tutorial shows you how to mirror a simple stateless
[PHP Guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
using Crane Runner and
[Tekton ClusterTasks](https://tekton.dev/docs/pipelines/tasks/#task-vs-clustertask).
Crane's export, transform, and apply functionality will be demonstrated through
executing Crane Runner ClusterTasks via
[Tekton TaskRuns](https://github.com/tektoncd/pipeline/blob/main/docs/taskruns.md).

# Roadmap

* Deploy Guestbook application in "source" cluster.
* Prepare for application mirror.
* Run `crane-export` ClusterTask.
* Run `crane-transform` ClusterTask.
* Run `crane-apply` ClusterTask.
* Run `kubectl-apply` ClusterTask.

# Before you begin

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
kustomize build github.com/konveyor/crane-runner/manifests\?ref=main | kubectl --context dest apply -f -
```

# Deploy Guestbook application in "source" cluster

You will be deploying
[Kubernetes' stateless guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
modified here to be consumable via kustomize.
The guestbook application consisists of:

* redis leader deployment and service
* redis follower deployment and service
* guestbook front-end deployment and service


```bash
kubectl --context src create namespace guestbook
kustomize build github.com/konveyor/crane-runner/examples/resources/guestbook\?ref=main | kubectl --context src --namespace guestbook apply -f -
kubectl --context src --namespace guestbook wait --for=condition=ready pod --selector=app=guestbook --timeout=180s
```

# Prepare for Application Mirror

You should first ensure that you have a `guestbook` namespace in the
"destination" cluster where we will mirror all resources from the "source"
cluster.

```bash
kubectl --context dest create namespace guestbook
```

Also, you must upload your kubeconfig as a secret. This will be used by the
ClusterTasks to mirror the application.

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
  name: stateless-app-mirror
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
$ kubectl --context dest --namespace guestbook get persistentvolumeclaims stateless-app-mirror
NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
stateless-app-mirror   Bound    pvc-8a692117-02a3-46e9-8a3a-43dade8f98d2   10Mi       RWO            standard       80s
```

# Run `crane-export` ClusterTask

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

# Run `crane-apply` ClusterTask

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

# Conclusions

Some words about what was done in this exercise and point to 002 and using
pipelineruns.
