#!/bin/bash

if [[ ! $NAME ]]; then
    echo "$0: NAME not specified"
    exit 1
fi

# Install an eduid virtualenv. To fool pip, we have to start a local pypiserver.

test -d /root/pypiserver || {
    python3 -mvenv /root/pypiserver

    /root/pypiserver/bin/pip install pypiserver passlib
    ls -l /root/pypiserver/bin
}

PYPI=0

term_handler() {
    if [ $PYPI -ne 0 ]; then
        kill -SIGTERM "$PYPI"
        wait "$PYPI"
    fi
    exit 143; # 128 + 15 -- SIGTERM
}

trap 'term_handler' SIGTERM


/root/pypiserver/bin/pypi-server \
    --fallback-url https://pypi.org/simple/ \
    --log-file /tmp/pypiserver.log \
    /build/wheels &
PYPI=$!


banner "${NAME}"

python3 -mvenv "/opt/eduid/${NAME}"
/opt/eduid/"${NAME}"/bin/pip install --upgrade pip wheel

if [[ $NAME == "webapp" ]]; then
    # some cheating for now, to avoid contamination by stuff on pypi.sunet.se
    /opt/eduid/"${NAME}"/bin/pip install --index-url https://pypi.sunet.se/simple vccs-client pysmscom pysaml2
fi

if [[ $NAME == "worker" ]]; then
    # some cheating for now, to avoid contamination by stuff on pypi.sunet.se
    /opt/eduid/"${NAME}"/bin/pip install --index-url https://pypi.sunet.se/simple pysmscom
fi

/opt/eduid/"${NAME}"/bin/pip install --index-url http://0.0.0.0:8080/ --trusted-host 0.0.0.0 "$@"

/opt/eduid/"${NAME}"/bin/pip freeze

echo "$0: Finished building virtualenv for ${NAME}"
