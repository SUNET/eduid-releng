ARG VERSION
ARG VCCS_LUNA_IMAGE_REF
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM ${VCCS_LUNA_IMAGE_REF}

ENV DEBIAN_FRONTEND noninteractive

# Add user/group before installing any packages to get consistent uid/gid
RUN groupadd --system eduid && useradd --system --shell /bin/false --gid eduid eduid

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      curl \
      build-essential \
      libcairo2-dev \
      libffi-dev \
      libfreetype-dev \
      libjpeg-dev \
      libpython3-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      pkg-config \
      python3-cffi \
      python3-dev \
      python3-venv \
      swig \
      xmlsec1 \
      zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/eduid && chown eduid: /var/log/eduid && chmod 770 /var/log/eduid

RUN mkdir -p /opt/eduid

COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /usr/local/bin/uv /usr/local/bin/uv
COPY --from=build /build/sources/eduid-backend/requirements /tmp/requirements

RUN uv venv /opt/eduid/fastapi && \
    uv pip install --python /opt/eduid/fastapi/bin/python --require-hashes --index-url https://pypi.sunet.se/simple \
      -r /tmp/requirements/fastapi_requirements.txt || \
    uv pip install --python /opt/eduid/fastapi/bin/python --require-hashes --index-url https://pypi.sunet.se/simple \
      -r /tmp/requirements/main.txt && \
    rm -rf /tmp/requirements && \
    apt-get purge -y \
      build-essential \
      libcairo2-dev \
      libffi-dev \
      libfreetype-dev \
      libjpeg-dev \
      libpython3-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      pkg-config \
      python3-cffi \
      python3-dev \
      python3-venv \
      swig \
      zlib1g-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

ADD start-fastapi.sh /start-fastapi.sh
ADD start-vccs.sh /start-vccs.sh

ARG VCCS_LUNA_IMAGE_TAG
ARG VCCS_LUNA_IMAGE_DIGEST
RUN echo "vccs luna image tag: $VCCS_LUNA_IMAGE_TAG" >> /revision.txt && \
  echo "vccs luna image digest: $VCCS_LUNA_IMAGE_DIGEST" >> /revision.txt

WORKDIR /opt/eduid

EXPOSE 8080

HEALTHCHECK --interval=27s CMD curl --max-time 20 http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash"]

CMD [ "/start-vccs.sh" ]
