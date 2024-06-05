FROM debian:stable

env DEBIAN_FRONTEND noninteractive

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
      pkg-config \
      python3-cffi \
      python3-dev \
      python3-venv \
      swig \
      sysvbanner \
      rsync \
      # xmlsec1 \
      zlib1g-dev \
      # for building xmlsec
      git \
      libtool \
      libtool-bin \
      libltdl7 \
      libltdl-dev \
      libxslt1.1 \
      libxslt1-dev \
      openssl \
      libssl3 \
      libssl-dev \
      libnspr4 \
      libnspr4-dev \
      libnss3 \
      libnss3-dev \
      libnss3-tools \
      libgnutls30 \
      libgcrypt20 \
      libgcrypt20-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/lsh123/xmlsec.git /tmp/xmlsec
WORKDIR /tmp/xmlsec
RUN git checkout 1.3.4
RUN ./autogen.sh
RUN make -j $(getconf _NPROCESSORS_ONLN) && make check && make install
RUN echo "Installed $(xmlsec1 --version)"
RUN rm /tmp/xmlsec -r
