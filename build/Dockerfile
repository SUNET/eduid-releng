FROM eduid-prebuild
ARG VERSION
ARG FLAVOR

RUN mkdir -p /build
COPY . /build/

WORKDIR /build
RUN make wheels

# Essentially create the same venv twice, to have the option to massage them differently down the line
RUN NAME=webapp /build/setup-venv.sh eduid-backend
RUN NAME=worker /build/setup-venv.sh eduid-backend

RUN ls -l /opt/eduid
