FROM eduid-prebuild
ARG VERSION
ARG FLAVOR

RUN mkdir -p /build
COPY . /build/

WORKDIR /build
RUN make wheels

RUN NAME=webapp /build/setup-venv.sh eduid-webapp
RUN NAME=worker /build/setup-venv.sh eduid-am eduid-msg eduid-lookup-mobile

RUN ls -l /opt/eduid
