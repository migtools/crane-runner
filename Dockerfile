FROM registry.ci.openshift.org/openshift/release:golang-1.17 as crane-bin
ENV GOFLAGS "-mod=mod"
WORKDIR /go/src/github.com/konveyor/crane
RUN git clone https://github.com/konveyor/crane.git .
RUN go build -a -o /build/crane main.go

FROM registry.access.redhat.com/ubi8/ubi:latest
COPY --from=crane-bin /build/crane /usr/bin/crane
RUN crane plugin-manager add OpenshiftPlugin
RUN curl -sL "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" | \
    tar xvzf - -C /usr/bin/ oc kubectl
RUN curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v4.4.1/kustomize_v4.4.1_linux_amd64.tar.gz" | \
    tar xvzf - -C /usr/bin/ kustomize
RUN dnf -y install git
ENTRYPOINT ["/usr/bin/crane"]
