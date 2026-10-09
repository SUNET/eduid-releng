#!/bin/bash

set -e

. /opt/eduid/fastapi/bin/activate

if [[ $# -eq 0 ]]; then
   if [[ "${PKCS11PIN:-}" == *\"* || "${PKCS11PIN:-}" == *\\* ||
         "${PKCS11PIN:-}" == *$'\n'* || "${PKCS11PIN:-}" == *$'\r'* ]]; then
      printf '%s\n' 'PKCS11PIN cannot contain double quotes, backslashes or line breaks with the upstream entrypoint.' >&2
      exit 1
   fi

   service_state_dir=${state_dir:-/opt/eduid/run}
   mkdir -p "$service_state_dir"
   chown eduid: "$service_state_dir"
   install -m 0640 -o root -g eduid /dev/null /config.py
   export GUNICORN_CMD_ARGS="--config /etc/pyeleven-gunicorn.conf.py${GUNICORN_CMD_ARGS:+ $GUNICORN_CMD_ARGS}"
fi

exec /bin/bash /usr/local/lib/luna-pyeleven/entrypoint.sh "$@"