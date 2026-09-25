ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM eduid-runtime-common:$VERSION

# Install those packages required by SATOSA:
#
#   xmlsec1
RUN apt-get update && \
    apt-get install -y \
      python3-minimal \
      xmlsec1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/sources/eduid-backend/src /opt/eduid/src
COPY --from=build /build/sources/eduid-backend/revision.txt /revision.txt
COPY --from=build /opt/uv-bootstrap /opt/uv-bootstrap
COPY --from=build /opt/eduid/satosa_scim /opt/eduid/satosa_scim

# Apply performance overlays for the satosa and saml2 packages without hardcoding a Python minor-version path.
COPY ./patches /opt/eduid/satosa_scim/patches
COPY --chmod=0755 ./apply-package-overlays.sh /opt/eduid/apply-package-overlays.sh
RUN /opt/eduid/apply-package-overlays.sh /opt/eduid/satosa_scim/bin/python /opt/eduid/satosa_scim/patches && \
  rm -rf /opt/eduid/satosa_scim/patches /opt/eduid/apply-package-overlays.sh

WORKDIR /opt/eduid

EXPOSE 8080

COPY start-satosa_scim.sh /start-satosa_scim.sh

# No health check endpoint in SATOSA
#HEALTHCHECK --interval=27s CMD curl --max-time 20 http://localhost:8080/status/healthy | grep -q STATUS_OK

ENTRYPOINT [ "/bin/bash"]

CMD [ "/start-satosa_scim.sh" ]
