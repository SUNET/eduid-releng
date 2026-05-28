ARG DEBIAN_VERSION
FROM debian:${DEBIAN_VERSION}

ARG UV_VERSION
ARG UV_RELEASE_ASSET
ARG UV_RELEASE_SHA256

ENV DEBIAN_FRONTEND=noninteractive

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
    && uv_archive="/tmp/${UV_RELEASE_ASSET}" \
    && uv_dir="${UV_RELEASE_ASSET%.tar.gz}" \
    && curl -LsSf -o "${uv_archive}" "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${UV_RELEASE_ASSET}" \
    && echo "${UV_RELEASE_SHA256}  ${uv_archive}" | sha256sum -c - \
    && tar -xzf "${uv_archive}" -C /tmp \
    && install "/tmp/${uv_dir}/uv" /usr/local/bin/uv \
    && rm -rf "${uv_archive}" "/tmp/${uv_dir}" \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
