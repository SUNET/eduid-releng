ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM debian:stable

env DEBIAN_FRONTEND noninteractive

RUN /bin/sed -i s/deb.debian.org/ftp.se.debian.org/g /etc/apt/sources.list

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      bind9-host \
      curl \
      iputils-ping \
      net-tools \
      netcat-openbsd \
      procps \
      python3-minimal \
      python3-distutils \
      xmlsec1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN addgroup --system eduid && adduser --system --shell /bin/false eduid

RUN mkdir -p /var/log/eduid && chown eduid: /var/log/eduid && chmod 770 /var/log/eduid

RUN mkdir -p /opt/eduid

COPY --from=build /build/wheels/ /build/wheels
COPY --from=build /opt/eduid/worker /opt/eduid/worker

ENTRYPOINT ["/bin/bash"]
