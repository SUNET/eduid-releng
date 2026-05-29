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
current_debian_digest=$(awk -F ' := ' '/^DEBIAN_DIGEST :=/ {print $2}' "${versions_file}")

# Track Debian through the current stable codename and resolve the matching
# multi-arch manifest digest from Docker Hub for an immutable base reference.
latest_debian_version=$(curl -fsSL https://deb.debian.org/debian/dists/stable/Release | awk -F ': ' '/^Codename:/ {print $2}')
docker_hub_token=$(curl -fsSL 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/debian:pull' | python3 -c 'import json, sys; print(json.load(sys.stdin)["token"])')
latest_debian_digest=$(curl -fsSI \
    -H "Authorization: Bearer ${docker_hub_token}" \
    -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json' \
    "https://registry-1.docker.io/v2/library/debian/manifests/${latest_debian_version}" | awk 'BEGIN {IGNORECASE=1} /^Docker-Content-Digest:/ {print $2}' | tr -d $'\r')

if [[ -z "${latest_debian_digest}" ]]; then
    echo "$0: failed to resolve debian digest for ${latest_debian_version}" >&2
    exit 1
fi

echo "Base image versions"
echo "  current debian tag:    ${current_debian_version}"
echo "  latest debian tag:     ${latest_debian_version}"
echo "  current debian digest: ${current_debian_digest}"
echo "  latest debian digest:  ${latest_debian_digest}"

if [[ "${current_debian_version}" == "${latest_debian_version}" && "${current_debian_digest}" == "${latest_debian_digest}" ]]; then
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
    -e "s|^DEBIAN_DIGEST := .*|DEBIAN_DIGEST := ${latest_debian_digest}|" \
    "${versions_file}" > "${tmp_file}"

mv "${tmp_file}" "${versions_file}"
trap - EXIT

echo "$0: updated ${versions_file}"