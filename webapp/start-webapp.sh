#!/bin/bash

set -e
set -x

. /opt/eduid/webapp/bin/activate

if [[ ! $eduid_name ]]; then
    echo "$0: Environment variable eduid_name not set (should be e.g. 'idp')"
    exit 1
fi

# These could be set from Puppet if multiple instances are deployed
eduid_entrypoint=${eduid_entrypoint-"eduid_webapp.${eduid_name}.run:app"}
base_dir=${base_dir-'/opt/eduid'}
project_dir=${project_dir-"${base_dir}/eduid-webapp/src"}
app_dir=${app_dir-"${project_dir}/${eduid_name}"}
cfg_dir=${cfg_dir-"${base_dir}/etc"}
# These *can* be set from Puppet, but are less expected to...
config_ns=${config_ns-"/eduid/webapp/${eduid_name}"}
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

extra_args=""
if [ -f "/opt/eduid/src/eduid-webapp/setup.py" ]; then
    # developer mode, restart on code changes
    extra_args="--reload"
fi

#
# Per-webapp initialisation
#
case "${eduid_name}" in
    "authn")
	saml2_settings="${saml2_settings-${cfg_dir}/saml2_settings.py}"
	metadata=${metadata-"${state_dir}/metadata.xml"}

	# Metadata generation
	if [ ! -s "${metadata}" ]; then
	    # Create file with local SP metadata
	    ls -l ${cfg_dir}
	    mount
	    cd "${cfg_dir}" && \
		/opt/eduid/webapp/bin/make_metadata.py "${saml2_settings}" | \
		    xmllint --format - > "${metadata}"
	fi
	;;
    *)
	;;
esac



echo ""
echo "$0: Starting ${eduid_name}"

export EDUID_CONFIG_NS=${EDUID_CONFIG_NS-${config_ns}}

echo "Reading settings from: ${EDUID_CONFIG_NS-'No namespace set'}"
exec start-stop-daemon --start -c eduid:eduid --exec \
     /opt/eduid/webapp/bin/gunicorn \
     --pidfile "${state_dir}/${eduid_name}.pid" \
     --user=eduid --group=eduid -- \
     --bind 0.0.0.0:8080 \
     --workers ${workers} --worker-class ${worker_class} \
     --threads ${worker_threads} --timeout ${worker_timeout} \
     --forwarded-allow-ips="${forwarded_allow_ips}" \
     --access-logfile "${log_dir}/${eduid_name}-access.log" \
     --error-logfile "${log_dir}/${eduid_name}-error.log" \
     --capture-output \
     ${extra_args} "${eduid_entrypoint}"
