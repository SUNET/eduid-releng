ARG VERSION
FROM eduid-build:$VERSION AS build

RUN cat /build/submodules.txt


FROM eduid-runtime-common:$VERSION

RUN apt-get update && \
    apt-get install -y \
      nginx \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# add revisions for upstream projects
COPY --from=build /build/sources/eduid-html/revision.txt /revision-html.txt
COPY --from=build /build/sources/eduid-front/revision.txt /revision-front.txt
COPY --from=build /build/sources/eduid-managed-accounts/revision.txt /revision-managed-accounts.txt

# setup nginx to run in fg
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# make sure we get rid of all default sites
RUN rm -f /etc/nginx/sites-enabled/*

# Copy nginx config from eduid-html repo
COPY --from=build /build/sources/eduid-html/docker/html.conf /etc/nginx/sites-enabled/html.conf

# Copy a blank index.html to /opt/eduid/www for health checks
COPY --from=build /build/sources/eduid-html/index.html /opt/eduid/www/index.html

# Copy react apps and other webapp dependencies to /opt/eduid/static/
COPY --from=build /build/sources/eduid-html/static /opt/eduid/static/
COPY --from=build /opt/eduid/eduid-front /opt/eduid/eduid-front/
COPY --from=build /opt/eduid/eduid-managed-accounts /opt/eduid/eduid-managed-accounts/

COPY start-html.sh /start-html.sh

HEALTHCHECK --interval=27s CMD curl --max-time 3 --silent --output /dev/null http://localhost || exit 1

ENTRYPOINT [ "/bin/bash"]

CMD [ "/start-html.sh" ]
