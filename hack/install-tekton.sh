#!/usr/bin/env bash

set -ex

# TODO(djzager): deal with context?
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.notags.yaml
kubectl --namespace tekton-pipelines wait --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s
