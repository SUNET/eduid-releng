#!/bin/bash

set -e
set -x

if [[ ! $NAME ]]; then
    echo "$0: NAME not specified"
    exit 1
fi

banner "${NAME}"

cd "/build/sources/${NAME}"

if [[ ! -f package-lock.json ]]; then
    echo "$0: /build/sources/${NAME}/package-lock.json is missing"
    echo "$0: release builds require a committed package-lock.json"
    exit 1
fi

npm ci --no-audit --no-fund

# project specific build commands
if [ "$NAME" == "eduid-front" ]; then
    npm run build-staging
    npm run build-production
    mkdir -p /opt/eduid/eduid-front
    mv "/build/sources/${NAME}/build/"* /opt/eduid/eduid-front/.
elif [ "$NAME" == "eduid-managed-accounts" ]; then
    npx vite build
    mkdir -p /opt/eduid/eduid-managed-accounts
    mv "/build/sources/${NAME}/dist/"* /opt/eduid/eduid-managed-accounts/.
fi

echo "$0: Finished building ${NAME}"
