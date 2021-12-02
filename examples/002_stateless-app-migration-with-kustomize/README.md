Stateless Application Migration with Kustomize
==============================================

This tutorial shows you how to migrate a simple stateless
[PHP Guestbook application](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
using Crane Runner, Kustomize, and
[Tekton ClusterTasks](https://tekton.dev/docs/pipelines/tasks/#task-vs-clustertask).
Unlike, in the previous exercise where the application was mirrored from one
namespace in the "source" cluster to the same namespace in the "destination"
cluster, here you will use a Kustomize overlay to import the workload into
the desired namespace.

If you just completed [Stateless Application
Mirror](../001_stateless-app-mirror/), then you can skip to ...

# Roadmap

* Start up "source" and "destination" clusters in minikube.
* Startup Guestbook application in "source" cluster.
* Startup Tekton in "destination" cluster.
* Apply Crane Runner ClusterTask manifests.
* Create [Tekton PipelineRun](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
    that migrates the Guestbook application.
