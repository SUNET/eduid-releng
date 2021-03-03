#!/bin/bash

set -e
set -x

if [[ ! $VERSION ]]; then
    echo "$0: VERSION not provided"
    exit 1
fi


# if VERSION is a DATETIME from the Makefile, the T has to be replaced with a dot
# to be PEP 440 compliant.
VERSION="$(echo $VERSION | tr T .)"

source ${VENV}/bin/activate

if [ ! -d "${SOURCES}" ]; then
    echo "$0: SOURCES not set"
    exit 1
fi

cd "${SOURCES}"

for repo in *; do
    pushd "${repo}"

    sed -ie "s/^version =.*/version = '${VERSION}'/g" setup.py

    for file in *irements.txt; do
	sed -ie "s/^\\(eduid-.*\\)==.* /\\1==${VERSION} /g" "${file}"
    done

    rm -rf build dist
    python setup.py bdist_wheel

    popd
done


