#!/usr/bin/env bash

command -v minikube >/dev/null 2>&1 || ( echo "Minikube not installed. Please install minikube." && exit 1 )

set -ex

minikube start --profile src
minikube start --profile dest