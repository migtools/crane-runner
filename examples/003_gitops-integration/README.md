GitOps Integration
==================

This tutorial shows you how Crane Runner can be used in conjunction with
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/), a GitOps continuous
delivery tool for Kubernetes, to migrate a simple stateless 
[PHP Guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/).

If you just completed [Stateless Application Migration](../002_stateless-app-migration-with-kustomize/),
then you can skip to
[Prepare for Application Migration](#prepare-for-application-migration).

# Roadmap

* Deploy Guestbook application in "source" cluster.
* Prepare for application migration.
* Convert Guestbook application from "source" cluster to Kustomize manifests
* Push manifests to GitHub using ClusterTaskCreate a GitHub repository to hold our Guestbook application manifests.
* Import application using Argo CD.

# Before you begin

You will need a "source" and "destination" Kubernetes cluster with Tekton,
the Crane Runner ClusterTasks, and Argo CD installed. Below are the steps
required for easy copy/paste:

```bash
# Start up "source" and "destination" clusters in minikube
curl -s "https://raw.githubusercontent.com/konveyor/crane/master/hack/minikube-clusters-start.sh" | bash

# Install Tekton
# See https://tekton.dev/docs/getting-started/ for help with installing Tekton
kubectl --context dest apply -f "https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml"
kubectl --context dest --namespace tekton-pipelines wait --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

# Install Crane Runner manifests
kustomize build github.com/konveyor/crane-runner/manifests\?ref=master | kubectl --context dest apply -f -

# Install Argo CD
# See https://argo-cd.readthedocs.io/en/stable/getting_started/ for help installing Argo CD
kubectl --context dest create namespace argocd
kubectl --context dest apply --namespace argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl --context dest --namespace argocd wait --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=180s
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
kustomize build github.com/konveyor/crane-runner/examples/resources/guestbook\?ref=master | kubectl --context src --namespace guestbook apply -f -
kubectl --context src --namespace guestbook wait --for=condition=ready pod --selector=app=guestbook --timeout=180s
```

# Prepare for Application Migration

First, create the `guestbook-gitops` namespace in the "destination" cluster
where you will migrate the guestbook application from the "source" cluster.

```bash
kubectl --context dest create namespace guestbook-gitops
```

You must upload your kubeconfig as a secret. This will be used by the
ClusterTasks to migrate the application.

```bash
kubectl config view --flatten | kubectl --context dest --namespace guestbook-gitops create secret generic kubeconfig --from-file=config=/dev/stdin
```

Next, you must ensure you have a GitHub "Personal access token". Navigate to
https://github.com/settings/tokens and select "Generate new token":

![GitHub Setting Screen](./GH_Token.png)

Configure and generate your personal access token:

![New personal access token](./GH_NewToken.png)

If successful, you should now see a generated token like below:

![Generated token](./GH_GeneratedToken.png)

Upload your token as a secret:

```bash
USER=${INSERT_YOUR_USERNAME}
PASS=${YOUR_GENERATED_GH_TOKEN}

cat <<EOF | kubectl --context dest --namespace guestbook-gitops apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: git-credentials
  # https://tekton.dev/docs/pipelines/auth/#basic-auth-for-git
  annotations:
    tekton.dev/git-0: https://github.com
type: kubernetes.io/basic-auth
stringData:
  username: ${USER}
  password: ${PASS}
```

Create a serviceAccount and attach your secret to it:

```bash
cat <<EOF | kubectl --context dest --namespace guestbook-gitops apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: guestbook-gitops-example
secrets:
  - name: git-credentials
EOF
```

Finally, after creating the `guestbook-gitops` namespace and uploading your kubeconfig and
git-credentials secrets, you need to reserve a PersistentVolume to hold the
exported manifests:

```bash
cat <<EOF | kubectl --context dest --namespace guestbook-gitops create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: guestbook-gitops-example
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
EOF
```

# Convert Guestbook Application from "source" cluster to Kustomize Manifests

Create Tekton PipelineRun that runs the `crane-export`, `crane-transform`, and
`crane-apply` ClusterTasks before `kustomize-namespace` to make the manifests
consumable via Kustomize.

Notice in the [PipelineRun](./pipelinerun.yaml), that the `shared-data`
workspace is referencing the `guestbook-gitops-example` PVC created earlier.
This is important as it's where the Kustomize manifests will be stored.

```bash
kubectl --context dest --namespace guestbook-gitops create -f "https://raw.githubusercontent.com/konveyor/crane-runner/examples/003_gitops-integration/pipelinerun.yaml"
```

At this stage, the Guestbook applicatoin's manifests should be safely stored in
the `guestbook-gitops-example` volume created earlier.

# Push Manifests to GitHub

Now you want to push your Kustomize manifests to GitHub. Before you do that, you
must create a GitHub repo to hold your Guestbook application manifests. 
Name it whatever you would like, ie `crane-guestbook-gitops`, and then create a
TaskRun that uploads the manifests.

```bash
cat <<EOF | kubectl --context dest --namespace guestbook-gitops create -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  generateName: guestbook-gitops-example-
spec:
  serviceAccountName: guestbook-gitops-example
  taskRef:
    name: git-init-push
    kind: ClusterTask
  params:
  - name: git-remote-url
    value: ${GIT_REMOTE_URL}
  - name: user-name
    value: "you@example.com"
  - name: user-email
    value: "Your Name"
  workspaces:
  - name: uninitialized-git-repo
    persistentVolumeClaim:
      claimName: guestbook-gitops-example
    subPath: kustomize
EOF
```

# Import Guestbook Application into Argo CD

```bash
cat <<EOF | kubectl --context dest --namespace argocd apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook-gitops
spec:
  source:
    path: app
    repoURL: ${GIT_REMOTE_URL}
    targetRevision: master
  destination:
    namespace: guestbook-gitops
    server: https://kubernetes.default.svc
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```
