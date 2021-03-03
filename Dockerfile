FROM docker.sunet.se/eduid/python3env AS build
ARG VERSION

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && apt-get -y install \
    devscripts \
    git \
    help2man \
    rsync \
    swig

RUN mkdir -p /build
COPY . /build/

WORKDIR /build
RUN (git describe; git log -n 1) > /build/revision.txt
RUN make all

FROM docker.sunet.se/eduid/python3env
ARG VERSION
COPY --from=build /build/wheels/ /build/wheels

RUN find /build -ls

RUN mkdir -p /opt/eduid

RUN python3 -mvenv /opt/eduid/webapp
RUN /opt/eduid/webapp/bin/pip install --extra-index-url file:///build/wheels/simple eduid-webapp

ENTRYPOINT ["/bin/bash"]
