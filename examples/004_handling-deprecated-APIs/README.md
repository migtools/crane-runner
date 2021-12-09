Migrating Deprecated APIs
============================

This tutorial shows you how to migrate deprecated Kubernetes API versions to
non-deprecated API versions using Crane Runner and kubectl-convert all in a
single Tekton Pipeline.

# Roadmap

* Start up "source" and "destination" clusters in minikube. In this example
    though, the "source" cluster will be an older version of Kubernetes.
* Startup Guestbook application in "source" cluster using `apps/v1beta2` API
    version of Deployments.
* Startup Tekton in "destination" cluster.
* Apply Crane Runner ClusterTask manifests.
* Attempt to migrate application via Tekton PipelineRun. It will fail to apply
    because of unsupported API versions.
* Create [Tekton PipelineRun](https://tekton.dev/docs/pipelines/pipelineruns/)
    that includes kubectl-convert step to completely migrate the application.
