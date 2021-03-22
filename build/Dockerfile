FROM eduid-prebuild
ARG VERSION
ARG FLAVOR

COPY . /build

WORKDIR /build
RUN make install

RUN ls -l /opt/eduid
RUN du -shc /opt/eduid/*
