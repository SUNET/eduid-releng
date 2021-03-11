FROM eduid-prebuild
ARG VERSION
ARG FLAVOR

COPY . /build

WORKDIR /build
RUN make install

# Essentially create the same venv twice, to have the option to massage them differently down the line
RUN NAME=webapp /build/setup-venv.sh eduid-backend
RUN NAME=worker /build/setup-venv.sh eduid-backend

RUN ls -l /opt/eduid
