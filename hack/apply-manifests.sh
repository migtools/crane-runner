#!/usr/bin/env bash

command -v yq >/dev/null 2>&1 || ( echo "yq not installed. Please install yq https://github.com/mikefarah/yq/#install" && exit 1 )

command -v kustomize >/dev/null 2>&1 || ( echo "kustomize not installed. Please install kustomizehttps://kubectl.docs.kubernetes.io/installation/kustomize/" && exit 1 )

# Use this to override the image to be used when running tasks
RUNNER_IMAGE="${RUNNER_IMAGE:-}"
CONTEXT="${CONTEXT:-dest}"

set -ex

if [ -z "${RUNNER_IMAGE}" ]; then
  kustomize build manifests/clustertasks | kubectl --context="${CONTEXT}" apply -f -
else
  kustomize build manifests/clustertasks | \
    runner="${RUNNER_IMAGE}" yq eval --exit-status \
    '.spec.steps[].image |= strenv(runner)' - | kubectl --context="${CONTEXT}" apply -f -
fi
