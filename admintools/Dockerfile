ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM debian:stable

ENV DEBIAN_FRONTEND noninteractive

# Add user/group before installing any packages to get consistent uid/gid
RUN addgroup --system eduid && adduser --system --shell /bin/false --ingroup eduid eduid

#
# Install tools that are helpful when troubleshooting
#
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/eduid && chown eduid: /var/log/eduid && chmod 770 /var/log/eduid

RUN mkdir -p /opt/eduid

COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /opt/eduid/admintools /opt/eduid/admintools

WORKDIR /opt/eduid

EXPOSE 8080

ADD start-admintools.sh /start-admintools.sh

# No health check endpoint in admintools
#HEALTHCHECK --interval=27s CMD curl --max-time 20 http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash", "/start-admintools.sh" ]
