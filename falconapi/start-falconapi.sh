#!/bin/bash

set -e
set -x

if [[ ! $eduid_name ]]; then
    echo "$0: Environment variable eduid_name not set (should be e.g. 'idp')"
    exit 1
fi

if [[ ! $eduid_entrypoint ]]; then
    echo "$0: Environment variable eduid_entrypoint not set (should be e.g. 'eduid.scimapi.run:api')"
    exit 1
fi

. /opt/eduid/falconapi/bin/activate

# These could be set from Puppet if multiple instances are deployed
base_dir=${base_dir-'/opt/eduid'}
project_dir=${project_dir-"${base_dir}/eduid-falconapi/src"}
app_dir=${app_dir-"${project_dir}/${eduid_name}"}
cfg_dir=${cfg_dir-"${base_dir}/etc"}
# These *can* be set from Puppet, but are less expected to...
log_dir=${log_dir-'/var/log/eduid'}
state_dir=${state_dir-"${base_dir}/run"}
workers=${workers-1}
worker_class=${worker_class-sync}
worker_threads=${worker_threads-1}
worker_timeout=${worker_timeout-30}
# Need to tell Gunicorn to trust the X-Forwarded-* headers
forwarded_allow_ips=${forwarded_allow_ips-'*'}

test -d "${log_dir}" && chown -R eduid: "${log_dir}"
test -d "${state_dir}" && chown -R eduid: "${state_dir}"

# set PYTHONPATH if it is not already set using Docker environment
export PYTHONPATH=${PYTHONPATH-${project_dir}}
echo "PYTHONPATH=${PYTHONPATH}"

# nice to have in docker run output, to check what
# version of something is actually running.
/opt/eduid/falconapi/bin/pip freeze
test -f /revision.txt && cat /revision.txt; true
test -f /submodules.txt && cat /submodules.txt; true

extra_args=""
if [ -f "/opt/eduid/DEVEL_MODE" ]; then
    # developer mode, restart on code changes
    extra_args="--reload"
fi

export PYTHONPATH="${PYTHONPATH:+${PYTHONPATH}:}/opt/eduid/src"

echo ""
echo "$0: Starting ${eduid_name}"

if [[ $EDUID_CONFIG_NS ]]; then
    # This is an override to control what configuration is loaded by this app -
    # it is not needed in the normal case (and jsconfig won't work if it is set
    # because it loads two configuration sections)
    echo "Reading settings from: ${EDUID_CONFIG_NS}"
fi

exec start-stop-daemon --start -c eduid:eduid --exec \
     /opt/eduid/falconapi/bin/gunicorn \
     --pidfile "${state_dir}/${eduid_name}.pid" \
     --user=eduid --group=eduid -- \
     --bind 0.0.0.0:8080 \
     --workers "${workers}" --worker-class "${worker_class}" \
     --threads "${worker_threads}" --timeout "${worker_timeout}" \
     --forwarded-allow-ips="${forwarded_allow_ips}" \
     --access-logfile "${log_dir}/${eduid_name}-access.log" \
     --error-logfile "${log_dir}/${eduid_name}-error.log" \
     --capture-output \
     ${extra_args} "${eduid_entrypoint}"
