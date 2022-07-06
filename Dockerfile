FROM quay.io/konveyor/crane:latest as crane-bin

FROM quay.io/openshift/origin-cli:latest as cli-bin
COPY ./config /config
RUN curl -sL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert" > /usr/local/bin/kubectl-convert && \
    chmod +x /usr/local/bin/kubectl-convert
RUN curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v4.4.1/kustomize_v4.4.1_linux_amd64.tar.gz" | \
    tar xvzf - -C /usr/local/bin/ kustomize
RUN kustomize build /config/default > /deploy.yaml

FROM registry.access.redhat.com/ubi8/ubi:latest
COPY --from=crane-bin  /usr/local/bin/crane /usr/local/bin/crane
COPY --from=cli-bin    /usr/bin/oc /usr/bin/oc
COPY --from=cli-bin    /usr/bin/kubectl /usr/bin/kubectl
COPY --from=cli-bin    /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=cli-bin    /usr/local/bin/kubectl-convert /usr/local/bin/kubectl-convert
COPY --from=cli-bin    /deploy.yaml /deploy.yaml

RUN crane plugin-manager add OpenShiftPlugin --version v0.0.3
RUN crane plugin-manager add ImageStreamPlugin

RUN dnf -y install git
ENTRYPOINT ["/usr/local/bin/crane"]
