ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM debian:stable

env DEBIAN_FRONTEND noninteractive

RUN /bin/sed -i s/deb.debian.org/ftp.se.debian.org/g /etc/apt/sources.list

# Add user/group before installing any packages to get consistent uid/gid
RUN addgroup --system eduid && adduser --system --shell /bin/false --ingroup eduid eduid

#
# Install tools that are helpful when troubleshooting, and some things needed in runtime by various webapps.
#
# xmlsec1		pysaml2
# libxml2-utils		authn and idp uses xmllint to format generated metadata
# libjpeg8              pillow
# zlib1g-dev            pillow
#
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      bind9-host \
      curl \
      iputils-ping \
      libjpeg-dev \
      ghostscript \
      libxml2-utils \
      net-tools \
      netcat-openbsd \
      procps \
      python3-distutils \
      python3-minimal \
      xmlsec1 \
      zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/eduid && chown eduid: /var/log/eduid && chmod 770 /var/log/eduid

RUN mkdir -p /opt/eduid

COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /opt/eduid/webapp /opt/eduid/webapp

WORKDIR /opt/eduid

EXPOSE 8080

ADD start-webapp.sh /start-webapp.sh

HEALTHCHECK --interval=27s CMD curl http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash"]

CMD [ "/start-webapp.sh" ]
