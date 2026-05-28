#!/bin/bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
versions_file="${repo_root}/releng-tool-versions.mk"

mode=${1:-check}

case "${mode}" in
    check|update)
        ;;
    *)
        echo "Usage: $0 [check|update]" >&2
        exit 2
        ;;
esac

builder_arch=$(uname -m)

# The releng pin file currently tracks the Linux x86_64 uv release asset.
if [[ "${builder_arch}" != "x86_64" ]]; then
    echo "$0: unsupported architecture ${builder_arch}; releng currently supports x86_64 builders only" >&2
    exit 2
fi

# Read the currently reviewed values from releng-tool-versions.mk.
current_version=$(awk -F ' := ' '/^UV_VERSION :=/ {print $2}' "${versions_file}")
current_asset=$(awk -F ' := ' '/^UV_RELEASE_ASSET :=/ {print $2}' "${versions_file}")
current_sha256=$(awk -F ' := ' '/^UV_RELEASE_SHA256 :=/ {print $2}' "${versions_file}")
current_debian_version=$(awk -F ' := ' '/^DEBIAN_VERSION :=/ {print $2}' "${versions_file}")
current_luna_image_version=$(awk -F ' := ' '/^LUNA_IMAGE_VERSION :=/ {print $2}' "${versions_file}")

# Track Debian through the current stable codename, which is what the Dockerfiles pin.
latest_debian_version=$(curl -fsSL https://deb.debian.org/debian/dists/stable/Release | awk -F ': ' '/^Codename:/ {print $2}')

# Track the latest reviewed Luna client tag from the registry, excluding floating aliases and dev tags.
latest_luna_image_version=$(curl -fsSL https://docker.sunet.se/v2/luna-client/tags/list | \
    python3 -c 'import json, re, sys
tags = json.load(sys.stdin).get("tags", [])
pattern = re.compile(r"^\d+(?:\.\d+)*-\d+(?:\.\d+)+$")
candidates = sorted((tag for tag in tags if pattern.match(tag)), key=lambda tag: [int(part) for part in re.split(r"[.-]", tag)])
if not candidates:
    raise SystemExit("no stable luna-client tags found")
print(candidates[-1])')

# Query the latest uv release metadata and derive the reviewed x86_64 asset tuple.
latest_json=$(curl -fsSL https://api.github.com/repos/astral-sh/uv/releases/latest)
latest_version=$(printf '%s' "${latest_json}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')
latest_asset="uv-x86_64-unknown-linux-gnu.tar.gz"
latest_sha256=$(curl -fsSL "https://github.com/astral-sh/uv/releases/download/${latest_version}/${latest_asset}.sha256" | awk '{print $1}')

echo "Releng build tool versions"
echo "  current debian:    ${current_debian_version}"
echo "  latest debian:     ${latest_debian_version}"
echo "  current luna image: ${current_luna_image_version}"
echo "  latest luna image:  ${latest_luna_image_version}"
echo "  current uv version: ${current_version}"
echo "  current uv asset: ${current_asset}"
echo "  current uv sha256: ${current_sha256}"
echo "  latest uv version:  ${latest_version}"
echo "  latest uv asset:    ${latest_asset}"
echo "  latest uv sha256:   ${latest_sha256}"

if [[ "${current_debian_version}" == "${latest_debian_version}" && "${current_luna_image_version}" == "${latest_luna_image_version}" && "${current_version}" == "${latest_version}" && "${current_asset}" == "${latest_asset}" && "${current_sha256}" == "${latest_sha256}" ]]; then
    echo "$0: releng tool versions are up to date"
    exit 0
fi

if [[ "${mode}" == "check" ]]; then
    echo "$0: releng tool versions need an update"
    exit 1
fi

# Rewrite the pin file atomically so an interrupted update does not leave it partial.
tmp_file=$(mktemp)
trap 'rm -f "${tmp_file}"' EXIT

sed \
    -e "s|^DEBIAN_VERSION := .*|DEBIAN_VERSION := ${latest_debian_version}|" \
    -e "s|^LUNA_IMAGE_VERSION := .*|LUNA_IMAGE_VERSION := ${latest_luna_image_version}|" \
    -e "s|^UV_VERSION := .*|UV_VERSION := ${latest_version}|" \
    -e "s|^UV_RELEASE_ASSET := .*|UV_RELEASE_ASSET := ${latest_asset}|" \
    -e "s|^UV_RELEASE_SHA256 := .*|UV_RELEASE_SHA256 := ${latest_sha256}|" \
    "${versions_file}" > "${tmp_file}"

mv "${tmp_file}" "${versions_file}"
trap - EXIT

echo "$0: updated ${versions_file}"