GitOps Integration
==================

This tutorial shows you how Crane Runner can be used in conjunction with
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/), a GitOps continuous
delivery tool for Kubernetes. You will migrate a simple stateless 
[PHP Guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/),
except this time you will commit the changes to a GitHub repository and onboard
the application into ArgoCD.

# Roadmap

* Deploy Guestbook application in "source" cluster.
* Prepare for application migration.
* Create a GitHub repository to store our results from `crane`.
* Explore new ClusterTasks.
* Migrate the Guestbook application using kustomize overlay in a 
    [Tekton PipelineRun](https://tekton.dev/docs/pipelines/pipelineruns/).
* Bring the application into "destination" cluster using ArgoCD.

# Before you begin

You will need a "source" and "destination" Kubernetes cluster with Tekton and
the Crane Runner ClusterTasks installed. Below are the steps required for easy
copy/paste:

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

