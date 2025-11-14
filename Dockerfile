# 1.) build helm-whatup from source (because there is no binary release for linux/arm64)

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.22-bookworm AS buildwhatup

ENV WHATUP_SOURCE_URL=https://github.com/fabmation-gmbh/helm-whatup/archive/refs/tags/v0.6.3.tar.gz

RUN curl -L -o /tmp/helm-whatup.tar.gz $WHATUP_SOURCE_URL && \
    mkdir /helm-whatup && \
    tar -xzf /tmp/helm-whatup.tar.gz --strip-components=1 -C /helm-whatup/ && \
    rm -f /tmp/helm-whatup.tar.gz

WORKDIR /helm-whatup

ARG TARGETOS
ARG TARGETARCH

ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}

RUN echo "Will run build with environment: GOOS=$GOOS GOARCH=$GOARCH" && make build

# 2.) get latest version of helm

FROM --platform=$TARGETPLATFORM docker.io/library/ubuntu:22.04 AS gethelm

RUN apt-get update && apt-get install -y curl git && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# 3.) build actual container image

FROM --platform=$TARGETPLATFORM docker.io/library/ubuntu:22.04

RUN apt-get update && apt-get install -y jq bsdmainutils msmtp && rm -rf /var/lib/apt/lists/*

COPY --from=gethelm /usr/local/bin/helm /usr/local/bin/

RUN mkdir /data && chown 1000:1000 /data

RUN groupadd -g 1000 linux && useradd -m -u 1000 -g linux linux
USER 1000
WORKDIR /home/linux

RUN mkdir -p .local/share/helm/plugins/helm-whatup/bin/

COPY --from=buildwhatup --chown=1000:1000 /helm-whatup/README.md /helm-whatup/LICENSE.md /helm-whatup/plugin.yaml /home/linux/.local/share/helm/plugins/helm-whatup/
COPY --from=buildwhatup --chown=1000:1000 /helm-whatup/bin/helm-whatup /home/linux/.local/share/helm/plugins/helm-whatup/bin/

ADD --chown=1000:1000 add_repos.sh run.sh /home/linux/

VOLUME /data

ENV SMTP_HOST="" \
    SMTP_PORT="587" \
    SMTP_TLS="on" \
    SMTP_AUTH="on" \
    SMTP_USER="" \
    SMTP_PASS="" \
    SMTP_FROM="" \
    SMTP_TO=""

CMD /home/linux/run.sh
