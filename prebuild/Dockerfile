FROM debian:stable

env DEBIAN_FRONTEND noninteractive

# Do this first of all to ensure consistent uid/gid in all the other images
RUN addgroup --system eduid && adduser --system --shell /bin/false eduid

RUN /bin/sed -i s/deb.debian.org/ftp.se.debian.org/g /etc/apt/sources.list

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      build-essential \
      libffi-dev \
      libjpeg-dev \
      libpython3-dev \
      libssl-dev \
      libxml2-dev \
      libxml2-utils \
      libxslt1-dev \
      python3-cffi \
      python3-dev \
      python3-venv \
      swig \
      sysvbanner \
      rsync \
      xmlsec1 \
      zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
