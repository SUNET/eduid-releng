#!/bin/bash

set -e
set -x

BUILD=$(date +%s)

source ${VENV}/bin/activate

if [ ! -d "${SOURCES}" ]; then
    echo "$0: SOURCES not set"
    exit 1
fi

cd "${SOURCES}"

for repo in *; do
    pushd "${repo}"

    git status
    git show --summary
    ls -l

    sed -ie "s/^version =.*/version = '${BUILD}'/g" setup.py

    for file in *irements.txt; do
	sed -ie "s/^\\(eduid-.*\\)==.* /\\1==${BUILD} /g" "${file}"
    done

    rm -rf build dist
    python setup.py bdist_wheel

    popd
done


