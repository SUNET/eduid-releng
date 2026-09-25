ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM eduid-runtime-common:$VERSION

# xmlsec1		pysaml2
# libxml2-utils		authn and idp uses xmllint to format generated metadata
# libjpeg8              pillow
# zlib1g-dev            pillow
RUN apt-get update && \
    apt-get install -y \
      libjpeg-dev \
      ghostscript \
      libxml2-utils \
      python3-minimal \
      xmlsec1 \
      zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /opt/uv-bootstrap /opt/uv-bootstrap
COPY --from=build /opt/eduid/webapp /opt/eduid/webapp

WORKDIR /opt/eduid

EXPOSE 8080

ADD start-webapp.sh /start-webapp.sh

HEALTHCHECK --interval=27s CMD curl --max-time 20 http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash"]

CMD [ "/start-webapp.sh" ]
