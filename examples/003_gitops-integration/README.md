GitOps Integration
==================

This tutorial shows you how Crane Runner can be used in conjunction with
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/), a GitOps continuous
delivery tool for Kubernetes. You will migrate a simple stateless 
[PHP Guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/),
except this time you will commit the changes to a GitHub repository and onboard
the application into ArgoCD.

# Roadmap

* Start up "source" and "destination" clusters in minikube.
* Startup Guestbook application in "source" cluster.
* Startup Tekton in "destination" cluster.
* Apply Crane Runner ClusterTask manifests.
* Startup ArgoCD in "destination" cluster.
* Create a GitHub repository to store our results from `crane`.
* Create [Tekton PipelineRun](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
    that prepares application from "source" cluster and commits them to the
    created GitHub repository.
* Bring the application into "destination" cluster using ArgoCD.
