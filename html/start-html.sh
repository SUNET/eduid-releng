#!/bin/sh

set -e

chgrp www-data /var/log/nginx

# nice to have in docker run output, to check what
# version of something is actually running.
test -f /revision-html.txt && printf "eduid-html\n" && cat /revision-html.txt; true
test -f /revision-front.txt && printf "eduid-front\n" && cat /revision-front.txt; true
test -f /revision-managed-accounts.txt && printf "eduid-managed-accounts\n" && cat /revision-managed-accounts.txt; true
test -f /submodules.txt && cat /submodules.txt; true

exec start-stop-daemon --start --exec \
     /usr/sbin/nginx \
     --pidfile "/var/run/nginx.pid" \
     --user=www-data --group=www-data
