#!/bin/bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
versions_file="${repo_root}/base-image-versions.mk"

mode=${1:-check}

case "${mode}" in
    check|update)
        ;;
    *)
        echo "Usage: $0 [check|update]" >&2
        exit 2
        ;;
esac

# Read the currently reviewed values from base-image-versions.mk.
current_debian_version=$(awk -F ' := ' '/^DEBIAN_VERSION :=/ {print $2}' "${versions_file}")

# Track Debian through the current stable codename, which is what the Dockerfiles pin.
latest_debian_version=$(curl -fsSL https://deb.debian.org/debian/dists/stable/Release | awk -F ': ' '/^Codename:/ {print $2}')

echo "Base image versions"
echo "  current debian: ${current_debian_version}"
echo "  latest debian:  ${latest_debian_version}"

if [[ "${current_debian_version}" == "${latest_debian_version}" ]]; then
    echo "$0: base image versions are up to date"
    exit 0
fi

if [[ "${mode}" == "check" ]]; then
    echo "$0: base image versions need an update"
    exit 1
fi

# Rewrite the pin file atomically so an interrupted update does not leave it partial.
tmp_file=$(mktemp)
trap 'rm -f "${tmp_file}"' EXIT

sed \
    -e "s|^DEBIAN_VERSION := .*|DEBIAN_VERSION := ${latest_debian_version}|" \
    "${versions_file}" > "${tmp_file}"

mv "${tmp_file}" "${versions_file}"
trap - EXIT

echo "$0: updated ${versions_file}"