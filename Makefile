RUNTIME          ?= docker
IMAGE_ORG        ?= quay.io/konveyor
IMAGE_NAME       ?= crane-runner
IMAGE_TAG        ?= $(shell git rev-parse --short HEAD)
RUNNER_IMAGE     ?= $(IMAGE_ORG)/$(IMAGE_NAME):$(IMAGE_TAG)

build-image: ## Build the crane-runner container image
	$(RUNTIME) build ${CONTAINER_BUILD_PARAMS} -t $(RUNNER_IMAGE) -f Dockerfile .

push-image: ## Push the crane-runner container image
	$(RUNTIME) push $(RUNNER_IMAGE)

build-push-image: build-image push-image ## Build and push crane-runner container image

manifests: ## Apply manifests to cluster
	RUNNER_IMAGE=$(RUNNER_IMAGE) ./hack/apply-manifests.sh

help: ## Show this help screen
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ''

.PHONY: build-image push-image build-push-image manifests
