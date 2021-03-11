#!/bin/bash

set -e
set -x

if [[ ! $eduid_name ]]; then
    echo "$0: Environment variable eduid_name not set (should be e.g. 'am')"
    exit 1
fi

# activate python virtualenv
. /opt/eduid/worker/bin/activate

# These could be set from Puppet if multiple instances are deployed
eduid_queue=${eduid_queue-$eduid_name}
eduid_entrypoint=${eduid_entrypoint-"eduid.workers.${eduid_name}.worker"}
# These *can* be set from Puppet, but are less expected to...
log_dir=${log_dir-'/var/log/eduid'}
logfile=${logfile-"${log_dir}/${eduid_name}.log"}

chown eduid: "${log_dir}"

celery_args=${celery_args-'--loglevel INFO'}
if [ -f /opt/eduid/src/${eduid_name}/setup.py -o \
     -f /opt/eduid/src/eduid?${eduid_name}/setup.py ]; then
    # eduid-dev environment
    celery_args="--loglevel DEBUG"
else
    if [ -f "${cfg_dir}/${app_name}_DEBUG" ]; then
	# eduid-dev environment
	celery_args="--loglevel DEBUG"
    fi
fi

touch "${logfile}"
chown eduid: "${logfile}"
chmod 640 "${logfile}"

# nice to have in docker run output, to check what
# version of something is actually running.
/opt/eduid/worker/bin/pip freeze
test -f /revision.txt && cat /revision.txt; true
test -f /submodules.txt && cat /submodules.txt; true

export PYTHONPATH="${PYTHONPATH:+${PYTHONPATH}:}/opt/eduid/src"

# this is a Python module name, so can't have hyphen
eduid_entrypoint=$(echo $eduid_entrypoint | tr '-' '_')

echo "$0: Starting Celery app '${eduid_name}' (queue: ${eduid_queue})"
exec celery --app="${eduid_entrypoint}" worker -Q "${eduid_queue}" --events \
     --uid eduid --gid eduid --logfile="${logfile}" \
    $celery_args
