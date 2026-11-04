ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM eduid-runtime-common:$VERSION

RUN apt-get update && \
    apt-get install -y \
      # Celery's Billiard dependency: hmac for connection authentication.
      # Message tasks use http.HTTPStatus; async queue workers use asyncio.
      # python3 guarantees the stdlib without relying on APT recommendations.
      python3 \
      xmlsec1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /opt/uv-bootstrap /opt/uv-bootstrap
COPY --from=build /opt/eduid/worker /opt/eduid/worker

COPY start-worker.sh /start-worker.sh
COPY worker_healthcheck /usr/local/bin

HEALTHCHECK --interval=27s --timeout=15s --start-period=10s CMD /usr/local/bin/worker_healthcheck

ENTRYPOINT ["/bin/bash"]

CMD [ "/start-worker.sh" ]
