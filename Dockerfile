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

RUN VENV=/opt/eduid/webapp make webapp

#RUN python3 -mvenv /build/eduid-webapp
#RUN /build/eduid-webapp/bin/pip install --extra-index-url file:///build/wheels/simple eduid-webapp
#RUN /opt/eduid/webapp/bin/pip install --extra-index-url file:///build/wheels/simple eduid-webapp
#RUN /opt/eduid/webapp/bin/pip install -vvv --index-url file:///build/wheels/simple --extra-index-url https://pypi.sunet.se/simple eduid-webapp



FROM docker.sunet.se/eduid/python3env
ARG VERSION

RUN mkdir -p /opt/eduid

COPY --from=build /build/wheels/ /build/wheels
COPY --from=build /opt/eduid/webapp /opt/eduid/webapp

ENTRYPOINT ["/bin/bash"]
