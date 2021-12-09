#!/usr/bin/env bash

set -ex

kind delete cluster --name src
kind delete cluster --name dest
