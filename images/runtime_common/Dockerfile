ARG DEBIAN_DIGEST
ARG DEBIAN_VERSION
FROM debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      bind9-host \
      curl \
      iputils-ping \
      net-tools \
      netcat-openbsd \
      procps \
    && groupadd --system eduid \
    && useradd --system --shell /bin/false --gid eduid eduid \
    && mkdir -p /var/log/eduid /opt/eduid \
    && chown eduid: /var/log/eduid \
    && chmod 770 /var/log/eduid \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*