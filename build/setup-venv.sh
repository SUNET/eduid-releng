#!/bin/bash

set -e
set -x

if [[ ! $NAME ]]; then
    echo "$0: NAME not specified"
    exit 1
fi

banner "${NAME}"

python3 -mvenv "/opt/eduid/${NAME}"
/opt/eduid/"${NAME}"/bin/pip install --upgrade pip wheel

# Install requirements - first look for a specific ${NAME}_requirements.txt (we don't have any today)
# and if not found - use the eduid-backend/requirements.txt.
req="/build/sources/eduid-backend/${NAME}_requirements.txt"
test -f "${req}" || req="/build/sources/eduid-backend/requirements.txt"
/opt/eduid/"${NAME}"/bin/pip install --index-url http://0.0.0.0:8080/ --trusted-host 0.0.0.0 -r "${req}"

/opt/eduid/"${NAME}"/bin/pip freeze

echo "$0: Finished building virtualenv for ${NAME}"
