Stateless Application Mirror
============================

This tutorial shows you how to mirror a simple stateless
[PHP Guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
using Crane Runner and
[Tekton ClusterTasks](https://tekton.dev/docs/pipelines/tasks/#task-vs-clustertask).
Crane's export, transform, and apply functionality will be demonstrated.

# Roadmap

* Start up "source" and "destination" clusters in minikube.
* Startup Guestbook application in "source" cluster.
* Startup Tekton in "destination" cluster.
* Apply Crane Runner ClusterTask manifests.
* Create [Tekton PipelineRun](https://tekton.dev/docs/pipelines/pipelineruns/)
    that mirrors the Guestbook application to the "destination" cluster.
