#!/bin/bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
versions_file="${repo_root}/versions/runtime-images.mk"

mode=${1:-check}

case "${mode}" in
    check|update)
        ;;
    *)
        echo "Usage: $0 [check|update]" >&2
        exit 2
        ;;
esac

# Read the currently reviewed VCCS runtime image tag.
current_vccs_luna_image_tag=$(awk -F ' := ' '/^VCCS_LUNA_IMAGE_TAG :=/ {print $2}' "${versions_file}")

# Track the latest reviewed Luna client tag from the registry.
latest_vccs_luna_image_tag=$(/usr/bin/bash -lc '
set -euo pipefail
latest=$(curl -fsSL https://docker.sunet.se/v2/luna-client/tags/list | python3 -c '\''import json, re, sys
tags = json.load(sys.stdin).get("tags", [])
pattern = re.compile(r"^\d+(?:\.\d+)*-\d+(?:\.\d+)+$")
candidates = sorted((tag for tag in tags if pattern.match(tag)), key=lambda tag: [int(part) for part in re.split(r"[.-]", tag)])
if not candidates:
    raise SystemExit("no stable luna-client tags found")
print(candidates[-1])'\'')
printf "%s" "${latest}"
')

echo "Runtime image versions"
echo "  current vccs luna tag:    ${current_vccs_luna_image_tag}"
echo "  latest vccs luna tag:     ${latest_vccs_luna_image_tag}"

if [[ "${current_vccs_luna_image_tag}" == "${latest_vccs_luna_image_tag}" ]]; then
    echo "$0: runtime image versions are up to date"
    exit 0
fi

if [[ "${mode}" == "check" ]]; then
    echo "$0: runtime image versions need an update"
    exit 1
fi

# Rewrite the pin file atomically so an interrupted update does not leave it partial.
tmp_file=$(mktemp)
trap 'rm -f "${tmp_file}"' EXIT

sed \
    -e "s|^VCCS_LUNA_IMAGE_TAG := .*|VCCS_LUNA_IMAGE_TAG := ${latest_vccs_luna_image_tag}|" \
    "${versions_file}" > "${tmp_file}"

mv "${tmp_file}" "${versions_file}"
trap - EXIT

echo "$0: updated ${versions_file}"