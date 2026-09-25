ARG DEBIAN_DIGEST
ARG DEBIAN_VERSION
FROM debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}

ENV DEBIAN_FRONTEND=noninteractive \
  PATH="/opt/uv-bootstrap/bin:${PATH}" \
  UV_PYTHON_DOWNLOADS=never

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      build-essential \
      curl \
      libcairo2-dev \
      libffi-dev \
      libfreetype-dev \
      libjpeg-dev \
      libpython3-dev \
      libssl-dev \
      libxml2-dev \
      libxml2-utils \
      libxslt1-dev \
      npm \
      pkg-config \
      python3-cffi \
      python3-dev \
      python3-venv \
      swig \
      sysvbanner \
      rsync \
      xmlsec1 \
      zlib1g-dev \
    && python3 -m venv /opt/uv-bootstrap \
    && /opt/uv-bootstrap/bin/pip install --upgrade uv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
