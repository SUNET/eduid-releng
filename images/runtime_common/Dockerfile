ARG DEBIAN_VERSION
FROM debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

ARG APT_REFRESH
RUN apt-get update -o APT::Update::Error-Mode=any && \
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