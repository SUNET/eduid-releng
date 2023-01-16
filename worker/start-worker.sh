#!/bin/bash

set -e
set -x

if [[ ! "${eduid_name}" ]]; then
    echo "$0: Environment variable eduid_name not set (should be e.g. 'am')"
    exit 1
fi

# activate python virtualenv
. /opt/eduid/worker/bin/activate

# These could be set from Puppet if multiple instances are deployed
base_dir=${base_dir-'/opt/eduid'}
eduid_queue=${eduid_queue-$eduid_name}
eduid_entrypoint=${eduid_entrypoint-"eduid.workers.${eduid_name}.worker"}
extra_sources_dir=${extra_sources_dir-"${base_dir}/sources"}
# These *can* be set from Puppet, but are less expected to...
log_dir=${log_dir-'/var/log/eduid'}
logfile=${logfile-"${log_dir}/${eduid_name}.log"}

chown eduid: "${log_dir}"

celery_args=${celery_args-'--loglevel INFO'}

touch "${logfile}"
chown eduid: "${logfile}"
chmod 640 "${logfile}"

# nice to have in docker run output, to check what
# version of something is actually running.
/opt/eduid/worker/bin/pip freeze
test -f /revision.txt && cat /revision.txt; true
test -f /submodules.txt && cat /submodules.txt; true

export PYTHONPATH="${PYTHONPATH:+${PYTHONPATH}:}/opt/eduid/src"

if [ -f "${extra_sources_dir}/eduid/dev-extra-modules.txt" ]; then
    echo ""
    echo "$0: Installing extra modules from ${extra_sources_dir}/eduid/dev-extra-modules.txt"
    /opt/eduid/worker/bin/pip install -r "${extra_sources_dir}/eduid/dev-extra-modules.txt"
fi

# this is a Python module name, so can't have hyphen
eduid_entrypoint=$(echo "${eduid_entrypoint}" | tr '-' '_')

if [ "x$NEW_QUEUE" != "x" ]; then
    echo "$0: Starting queue worker '${eduid_name}'"
    exec start-stop-daemon --start -c eduid:eduid --exec \
        /opt/eduid/worker/bin/python \
        --pidfile "${eduid_name}.pid" \
        --user=eduid --group=eduid -- \
        -m ${eduid_entrypoint}
else
    echo "$0: Starting Celery app '${eduid_name}' (queue: ${eduid_queue})"
    exec celery --app="${eduid_entrypoint}" worker -Q "${eduid_queue}" --events \
         --uid eduid --gid eduid --logfile="${logfile}" \
        $celery_args
fi
