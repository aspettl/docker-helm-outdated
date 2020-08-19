FROM ubuntu:20.04 AS builder

RUN apt-get update && apt-get install -y curl git && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

RUN groupadd -g 1000 linux && useradd -m -u 1000 -g linux linux
USER 1000
WORKDIR /home/linux

RUN helm plugin install https://github.com/fabmation-gmbh/helm-whatup && \
    rm -rf /tmp/helm-whatup*


FROM ubuntu:20.04

RUN apt-get update && apt-get install -y jq bsdmainutils msmtp && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/helm /usr/local/bin/

RUN mkdir /data && chown 1000:1000 /data

RUN groupadd -g 1000 linux && useradd -m -u 1000 -g linux linux
USER 1000
WORKDIR /home/linux

COPY --from=builder --chown=1000:1000 /home/linux/.local /home/linux/.local

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