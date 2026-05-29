#!/bin/bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
versions_file="${repo_root}/build-toolchain-versions.mk"

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

# The build toolchain pin file currently tracks the Linux x86_64 uv release asset.
if [[ "${builder_arch}" != "x86_64" ]]; then
    echo "$0: unsupported architecture ${builder_arch}; releng currently supports x86_64 builders only" >&2
    exit 2
fi

# Read the currently reviewed values from build-toolchain-versions.mk.
current_version=$(awk -F ' := ' '/^UV_VERSION :=/ {print $2}' "${versions_file}")
current_asset=$(awk -F ' := ' '/^UV_RELEASE_ASSET :=/ {print $2}' "${versions_file}")
current_sha256=$(awk -F ' := ' '/^UV_RELEASE_SHA256 :=/ {print $2}' "${versions_file}")

# Query the latest uv release metadata and derive the reviewed x86_64 asset tuple.
latest_json=$(curl -fsSL https://api.github.com/repos/astral-sh/uv/releases/latest)
latest_version=$(printf '%s' "${latest_json}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')
latest_asset="uv-x86_64-unknown-linux-gnu.tar.gz"
latest_sha256=$(curl -fsSL "https://github.com/astral-sh/uv/releases/download/${latest_version}/${latest_asset}.sha256" | awk '{print $1}')

echo "Build toolchain versions"
echo "  current uv version: ${current_version}"
echo "  current uv asset: ${current_asset}"
echo "  current uv sha256: ${current_sha256}"
echo "  latest uv version:  ${latest_version}"
echo "  latest uv asset:    ${latest_asset}"
echo "  latest uv sha256:   ${latest_sha256}"

if [[ "${current_version}" == "${latest_version}" && "${current_asset}" == "${latest_asset}" && "${current_sha256}" == "${latest_sha256}" ]]; then
    echo "$0: build toolchain versions are up to date"
    exit 0
fi

if [[ "${mode}" == "check" ]]; then
    echo "$0: build toolchain versions need an update"
    exit 1
fi

# Rewrite the pin file atomically so an interrupted update does not leave it partial.
tmp_file=$(mktemp)
trap 'rm -f "${tmp_file}"' EXIT

sed \
    -e "s|^UV_VERSION := .*|UV_VERSION := ${latest_version}|" \
    -e "s|^UV_RELEASE_ASSET := .*|UV_RELEASE_ASSET := ${latest_asset}|" \
    -e "s|^UV_RELEASE_SHA256 := .*|UV_RELEASE_SHA256 := ${latest_sha256}|" \
    "${versions_file}" > "${tmp_file}"


mv "${tmp_file}" "${versions_file}"
trap - EXIT

echo "$0: updated ${versions_file}"