ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM debian:stable

env DEBIAN_FRONTEND noninteractive

RUN /bin/sed -i s/deb.debian.org/ftp.se.debian.org/g /etc/apt/sources.list

#
# Install tools that are helpful when troubleshooting, and some things needed in runtime by various webapps.
#
# xmlsec1		pysaml2
# libxml2-utils		authn and idp uses xmllint to format generated metadata
#
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
      libxml2-utils \
      xmlsec1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN addgroup --system eduid && adduser --system --shell /bin/false eduid

RUN mkdir -p /var/log/eduid && chown eduid: /var/log/eduid && chmod 770 /var/log/eduid

RUN mkdir -p /opt/eduid

COPY --from=build /build/wheels/ /build/wheels
COPY --from=build /opt/eduid/webapp /opt/eduid/webapp

VOLUME ["/opt/eduid/etc", "/opt/eduid/run", "/opt/eduid/src", "/var/log"]

WORKDIR /opt/eduid

EXPOSE 8080

ADD start-webapp.sh /start-webapp.sh

HEALTHCHECK --interval=53s CMD curl http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash"]

CMD [ "/start-webapp.sh" ]
