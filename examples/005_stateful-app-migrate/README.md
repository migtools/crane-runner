Stateful Application Migration
==============================

This tutorial demonstrates the migration of a stateful applicaiton,
[Wordpress and MySQL with Persistent
Volumes](https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/),
using Crane's transfer-pvc functionality in a Tekton Pipeline.

# Roadmap

* Start up "source" and "destination" clusters in minikube.
* Startup Wordpress application in "source" cluster.
* Startup Tekton in "destination" cluster.
* Apply Crane Runner ClusterTask manifests.
* Migrate application to "destination" cluster via
    [Tekton PipelineRun](https://tekton.dev/docs/pipelines/pipelineruns/).
