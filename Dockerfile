FROM registry.ci.openshift.org/openshift/release:golang-1.16 as crane-bin

ENV GOFLAGS "-mod=mod"
WORKDIR /go/src/github.com/konveyor/crane

RUN git clone https://github.com/konveyor/crane.git .
RUN go build -a -o /build/crane main.go

FROM registry.access.redhat.com/ubi8/ubi:latest

COPY --from=crane-bin /build/crane /crane
RUN /crane plugin-manager add OpenshiftPlugin

# Helpful tools
# TODO(djzager): Determine want can stay and what must go
RUN curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz | \
    tar xvzf - -C /usr/bin/ oc kubectl
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.16.1/yq_linux_amd64.tar.gz | \
    tar xvzf - -C /usr/bin/ ./yq_linux_amd64 && \
    mv /usr/bin/yq_linux_amd64 /usr/bin/yq

CMD ["/crane"]
