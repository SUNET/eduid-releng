#!/bin/bash

set -e
set -x

if [[ ! $eduid_name ]]; then
    echo "$0: Environment variable eduid_name not set (should be e.g. 'idp')"
    exit 1
fi

. /opt/eduid/webapp/bin/activate

# These could be set from Puppet if multiple instances are deployed
eduid_entrypoint=${eduid_entrypoint-"eduid.webapp.${eduid_name}.run:app"}
base_dir=${base_dir-'/opt/eduid'}
project_dir=${project_dir-"${base_dir}/eduid-webapp/src"}
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

chown -R eduid: "${log_dir}" "${state_dir}"

# set PYTHONPATH if it is not already set using Docker environment
export PYTHONPATH=${PYTHONPATH-${project_dir}}
echo "PYTHONPATH=${PYTHONPATH}"

# nice to have in docker run output, to check what
# version of something is actually running.
/opt/eduid/webapp/bin/pip freeze
test -f /revision.txt && cat /revision.txt; true
test -f /submodules.txt && cat /submodules.txt; true

extra_args=""
if [ -f "/opt/eduid/src/eduid-webapp/setup.py" ]; then
    # developer mode, restart on code changes
    extra_args="--reload"
fi

#
# Per-webapp initialisation
#
case "${eduid_name}" in
    'authn'|'idp')
	saml2_settings="${saml2_settings-${cfg_dir}/saml2_settings.py}"
	metadata=${metadata-"${state_dir}/metadata.xml"}

	if [[ ! -f "${saml2_settings}" ]]; then
	    echo "$0: SAML2 settings file ${saml2_settings} NOT FOUND, can't generate ${metadata}"
	else
	    # Metadata generation, if it does not exist already
	    if [ ! -s "${metadata}" ]; then
		_dir=$(dirname "${saml2_settings}")
		cd "${_dir}"
		/opt/eduid/webapp/bin/make_metadata.py "${saml2_settings}" | \
		    xmllint --format - > "${metadata}"
	    fi
	fi
	;;
    *)
	;;
esac

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
     /opt/eduid/webapp/bin/gunicorn \
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
