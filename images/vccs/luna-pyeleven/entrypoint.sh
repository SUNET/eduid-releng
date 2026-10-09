#!/bin/bash

if [[ -z "${PYELEVEN_ARGS}" ]]; then
	PYELEVEN_ARGS="-w5"
fi

if [[ -z "${PYELEVEN_PORT}" ]]; then
	PYELEVEN_PORT="8000"
fi

if [[ $# -eq 0 ]]; then
	cat >/config.py <<EOF
DEBUG = True
PKCS11MODULE = "/usr/safenet/lunaclient/lib/libCryptoki2_64.so"
PKCS11PIN = "${PKCS11PIN}"
EOF
	exec gunicorn -b "0.0.0.0:${PYELEVEN_PORT}" "${PYELEVEN_ARGS}" pyeleven:app
else
	cd /tmp || exit
	exec "$@"
fi
