ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM eduid-runtime-common:$VERSION

RUN apt-get update && \
    apt-get install -y \
      python3-minimal \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /opt/eduid/admintools /opt/eduid/admintools

WORKDIR /opt/eduid

EXPOSE 8080

COPY start-admintools.sh /start-admintools.sh

# No health check endpoint in admintools
#HEALTHCHECK --interval=27s CMD curl --max-time 20 http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash", "/start-admintools.sh" ]
