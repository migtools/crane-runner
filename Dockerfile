FROM registry.ci.openshift.org/openshift/release:golang-1.16 as crane-bin

ENV GOFLAGS "-mod=mod"
WORKDIR /go/src/github.com/konveyor/crane

RUN git clone https://github.com/konveyor/crane.git .
RUN go build -a -o /build/crane main.go

FROM registry.access.redhat.com/ubi8/ubi:latest
RUN curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz | \
    tar xvzf - -C /usr/bin/ oc kubectl
COPY --from=crane-bin /build/crane /crane
RUN /crane plugin-manager add OpenshiftPlugin

CMD ["/crane"]
