#!/bin/bash

# Stop on command failures and trace commands for startup diagnostics.
set -e
set -x

# Luna client installation provided by the vendor base image.
SAFENET=/usr/safenet/lunaclient

# Derive numbered HSM server entries from certificate filenames and collect
# their certificates into the CA bundle used by the Luna client.
server_entries=""
N=0
rm -f /tmp/CAFile.pem
for cert in `find ${SAFENET}/cert/server -name \*Cert.pem`; do
   hsm=`basename $cert Cert.pem`
   NN=`printf "%02d" $N`
   printf -v server_entries '%s   ServerName%s = %s;\n   ServerPort%s = 1792;\n   ServerHtl%s = 0;\n' \
      "$server_entries" "$NN" "$hsm" "$NN" "$NN"
   N=`expr ${N} + 1`
   cat $cert >> /tmp/CAFile.pem
done

# Render only supported placeholders without evaluating the template as code.
# Include the final line even when the template has no trailing newline.
while IFS= read -r config_line || [[ -n "$config_line" ]]; do
   if [[ "$config_line" == '${SERVER_ENTRIES}' ]]; then
      printf '%s' "$server_entries"
   else
      config_line=${config_line//'${SAFENET}'/"${SAFENET}"}
      printf '%s\n' "${config_line//'${HOSTNAME}'/"${HOSTNAME}"}"
   fi
done < /etc/Chrystoki.conf.template > /etc/Chrystoki.conf

# Append deployment-specific configuration fragments in filename order.
if [ -d /etc/Chrystoki.conf.d ]; then
   cat /etc/Chrystoki.conf.d/*.conf >> /etc/Chrystoki.conf
fi

# Make Luna tools, including vtl, available for certificate creation.
export PATH=/usr/safenet/lunaclient/bin:$PATH

# Generate the hostname-specific client pair if either file is missing.
# Keep new private keys root-owned and readable only by root and the eduid group.
if [ ! -f "${SAFENET}/cert/client/${HOSTNAME}.pem" -o ! -f "${SAFENET}/cert/client/${HOSTNAME}Key.pem" ]; then
   mkdir -p "${SAFENET}/cert/client"
   vtl createCert -n ${HOSTNAME}
   chown root:eduid "${SAFENET}/cert/client/${HOSTNAME}Key.pem"
   chmod 0640 "${SAFENET}/cert/client/${HOSTNAME}Key.pem"
fi

# Tell the application which 64-bit Luna PKCS#11 library to load.
export PKCS11MODULE="/usr/safenet/lunaclient/lib/libCryptoki2_64.so"

# VCCS and pyeleven run as separate services in this container. Supervise both
# so container signals reach each service and either one's exit stops the other.
service_pids=()
stop_services() {
   # Ignore further shutdown signals while stopping and reaping both services.
   trap '' TERM INT
   if [[ ${#service_pids[@]} -gt 0 ]]; then
      kill -TERM "${service_pids[@]}" 2>/dev/null || true
      wait "${service_pids[@]}" 2>/dev/null || true
   fi
}

# Forward container termination to both services and report the signal exit status.
trap 'stop_services; exit 143' TERM
trap 'stop_services; exit 130' INT

# Each launcher execs Gunicorn, so these PIDs remain the service master PIDs.
/bin/bash /start-pyeleven.sh &
service_pids+=("$!")

/start-fastapi.sh &
service_pids+=("$!")

# If either service exits, stop its sibling rather than leave a partial runtime.
service_status=0
wait -n "${service_pids[@]}" || service_status=$?
stop_services
# Even a clean service exit is unexpected while the container should be running.
if [[ $service_status -eq 0 ]]; then
   service_status=1
fi
exit "$service_status"
