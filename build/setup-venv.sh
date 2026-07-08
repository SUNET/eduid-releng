#!/bin/bash

set -e
set -x

if [[ ! $NAME ]]; then
    echo "$0: NAME not specified"
    exit 1
fi

banner "${NAME}"

if ! command -v uv >/dev/null; then
    echo "$0: uv not available"
    exit 1
fi

venv="/opt/eduid/${NAME}"
venv_python="${venv}/bin/python"

uv venv "${venv}"

# Install requirements - first look for a specific ${NAME}_requirements.txt (we don't have any today)
# and if not found - use the eduid-backend/requirements.txt.
req="/build/sources/eduid-backend/requirements/${NAME}_requirements.txt"
test -f "${req}" || req="/build/sources/eduid-backend/requirements/main.txt"
ls -l "$(dirname "${req}")"
ls -l "${req}"
uv pip install --python "${venv_python}" --require-hashes --index-url https://pypi.sunet.se/simple -r "${req}"

uv pip freeze --python "${venv_python}"

echo "$0: Finished building virtualenv for ${NAME}"
