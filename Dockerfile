FROM registry.ci.openshift.org/openshift/release:golang-1.17 as plugin-bin
ENV GOFLAGS "-mod=mod"
WORKDIR /go/src/github.com/konveyor/crane-plugin-openshift
RUN git clone -b wh-csvs https://github.com/djzager/crane-plugin-openshift.git .
RUN go build -a -o /build/OpenShiftPlugin cmd.go openshift.go

FROM registry.ci.openshift.org/openshift/release:golang-1.17 as crane-bin
ENV GOFLAGS "-mod=mod"
WORKDIR /go/src/github.com/konveyor/crane
RUN git clone https://github.com/konveyor/crane.git .
RUN go build -a -o /build/crane main.go

FROM registry.redhat.io/openshift4/ose-cli:latest as cli-bin
COPY ./config /config
RUN curl -sL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert" > /usr/local/bin/kubectl-convert && \
    chmod +x /usr/local/bin/kubectl-convert
RUN curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v4.4.1/kustomize_v4.4.1_linux_amd64.tar.gz" | \
    tar xvzf - -C /usr/local/bin/ kustomize
RUN kustomize build /config/default > /deploy.yaml

FROM registry.redhat.io/ubi8/ubi:latest
COPY --from=crane-bin  /build/crane /usr/local/bin/crane
COPY --from=cli-bin    /usr/bin/oc /usr/bin/oc
COPY --from=cli-bin    /usr/bin/kubectl /usr/bin/kubectl
COPY --from=cli-bin    /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=cli-bin    /usr/local/bin/kubectl-convert /usr/local/bin/kubectl-convert
COPY --from=cli-bin    /deploy.yaml /deploy.yaml

RUN crane plugin-manager add OpenShiftPlugin
COPY --from=plugin-bin /build/OpenShiftPlugin /plugins/managed/default/OpenShiftPlugin

RUN dnf -y install git
ENTRYPOINT ["/usr/local/bin/crane"]
