#!/bin/bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
versions_file="${repo_root}/runtime-image-versions.mk"

mode=${1:-check}

case "${mode}" in
    check|update)
        ;;
    *)
        echo "Usage: $0 [check|update]" >&2
        exit 2
        ;;
esac

# Read the currently reviewed VCCS runtime image identity.
current_vccs_luna_image_tag=$(awk -F ' := ' '/^VCCS_LUNA_IMAGE_TAG :=/ {print $2}' "${versions_file}")
current_vccs_luna_image_digest=$(awk -F ' := ' '/^VCCS_LUNA_IMAGE_DIGEST :=/ {print $2}' "${versions_file}")

# Track the latest reviewed Luna client tag from the registry and resolve it to
# an immutable manifest digest in one network flow.
readarray -t latest_luna_identity < <(/usr/bin/bash -lc '
set -euo pipefail
latest=$(curl -fsSL https://docker.sunet.se/v2/luna-client/tags/list | python3 -c '\''import json, re, sys
tags = json.load(sys.stdin).get("tags", [])
pattern = re.compile(r"^\d+(?:\.\d+)*-\d+(?:\.\d+)+$")
candidates = sorted((tag for tag in tags if pattern.match(tag)), key=lambda tag: [int(part) for part in re.split(r"[.-]", tag)])
if not candidates:
    raise SystemExit("no stable luna-client tags found")
print(candidates[-1])'\'')
headers=$(curl -fsSI -H '\''Accept: application/vnd.docker.distribution.manifest.v2+json'\'' "https://docker.sunet.se/v2/luna-client/manifests/${latest}")
digest=$(printf "%s" "${headers}" | awk '\''BEGIN {IGNORECASE=1} /^Docker-Content-Digest:/ {print $2}'\'' | tr -d $'\''\r'\'')
if [[ -z "${digest}" ]]; then
    echo "failed to resolve luna-client digest for tag ${latest}" >&2
    exit 1
fi
printf "%s\n%s\n" "${latest}" "${digest}"
')

if [[ ${#latest_luna_identity[@]} -ne 2 ]]; then
    echo "$0: failed to resolve luna-client tag and digest" >&2
    exit 1
fi

latest_vccs_luna_image_tag=${latest_luna_identity[0]}
latest_vccs_luna_image_digest=${latest_luna_identity[1]}

echo "Runtime image versions"
echo "  current vccs luna tag:    ${current_vccs_luna_image_tag}"
echo "  latest vccs luna tag:     ${latest_vccs_luna_image_tag}"
echo "  current vccs luna digest: ${current_vccs_luna_image_digest}"
echo "  latest vccs luna digest:  ${latest_vccs_luna_image_digest}"

if [[ "${current_vccs_luna_image_tag}" == "${latest_vccs_luna_image_tag}" && "${current_vccs_luna_image_digest}" == "${latest_vccs_luna_image_digest}" ]]; then
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
    -e "s|^VCCS_LUNA_IMAGE_DIGEST := .*|VCCS_LUNA_IMAGE_DIGEST := ${latest_vccs_luna_image_digest}|" \
    "${versions_file}" > "${tmp_file}"

mv "${tmp_file}" "${versions_file}"
trap - EXIT

echo "$0: updated ${versions_file}"