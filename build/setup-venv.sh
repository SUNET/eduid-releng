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

if ! system_python=$(command -v python3); then
    echo "$0: python3 not available"
    exit 1
fi

backend_project="/build/sources/eduid-backend"
requirements_dir="${backend_project}/requirements"
venv="/opt/eduid/${NAME}"
venv_python="${venv}/bin/python"

export UV_PYTHON_DOWNLOADS=never

uv venv --project "${backend_project}" --python "${system_python}" --relocatable --link-mode copy "${venv}"

# Install requirements - first look for a specific ${NAME}_requirements.txt (we don't have any today)
# and if not found - use the eduid-backend/requirements.txt.
req="${requirements_dir}/${NAME}_requirements.txt"
test -f "${req}" || req="${requirements_dir}/main.txt"
ls -l "$(dirname "${req}")"
ls -l "${req}"
uv pip install --python "${venv_python}" --require-hashes --index-url https://pypi.sunet.se/simple -r "${req}"
uv pip install --python "${venv_python}" setuptools
uv pip install --python "${venv_python}" --no-deps --no-build-isolation "${backend_project}"

uv pip freeze --python "${venv_python}"

echo "$0: Finished building virtualenv for ${NAME}"
