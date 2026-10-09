ARG VERSION
ARG VCCS_LUNA_IMAGE_REF
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM ${VCCS_LUNA_IMAGE_REF}

ENV DEBIAN_FRONTEND=noninteractive \
  UV_PYTHON_DOWNLOADS=never

# The Luna base does not inherit eduid-runtime-common's user or log setup.
# Create eduid before packages for consistent uid/gid, then prepare its log directory.
RUN groupadd --system eduid && useradd --system --shell /bin/false --gid eduid eduid
RUN mkdir -p /var/log/eduid && chown eduid: /var/log/eduid && chmod 770 /var/log/eduid

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      curl \
      python3-minimal \
      xmlsec1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

  COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /opt/uv-bootstrap /opt/uv-bootstrap
COPY --from=build /opt/eduid/fastapi /opt/eduid/fastapi

COPY fastapi/start-fastapi.sh /start-fastapi.sh
COPY vccs/start-vccs.sh /start-vccs.sh
COPY vccs/Chrystoki.conf.template /etc/Chrystoki.conf.template

ARG VCCS_LUNA_IMAGE_TAG
RUN echo "vccs luna image tag: $VCCS_LUNA_IMAGE_TAG" >> /revision.txt

WORKDIR /opt/eduid

EXPOSE 8080

HEALTHCHECK --interval=27s CMD curl --max-time 20 http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash"]

CMD [ "/start-vccs.sh" ]
