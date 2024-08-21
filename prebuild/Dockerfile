FROM debian:stable

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      build-essential \
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*
