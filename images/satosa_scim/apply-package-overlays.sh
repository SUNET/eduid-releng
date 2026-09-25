#!/bin/bash

# In pseudo-code: 
#
# for each patch:
#   find installed package location via Python import machinery
#   verify source exists
#   verify target exists
#   cp source target

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <venv-python> <overlay-root>" >&2
    exit 1
fi

venv_python="$1"
overlay_root="$2"
manifest="${overlay_root}/manifest.txt"

if [[ ! -x "${venv_python}" ]]; then
    echo "python interpreter not found: ${venv_python}" >&2
    exit 1
fi

if [[ ! -f "${manifest}" ]]; then
    echo "overlay manifest not found: ${manifest}" >&2
    exit 1
fi

resolve_package_dir() {
    local package_name="$1"

    # Resolve the installed import-package location inside the target venv
    # instead of guessing a lib/pythonX.Y/site-packages path.
    "${venv_python}" - "$package_name" <<'PY'
import importlib.util
import pathlib
import sys

package_name = sys.argv[1]
spec = importlib.util.find_spec(package_name)
if spec is None:
    raise SystemExit(f"python package not found: {package_name}")

locations = spec.submodule_search_locations
if locations:
    print(pathlib.Path(next(iter(locations))).resolve())
elif spec.origin:
    print(pathlib.Path(spec.origin).resolve().parent)
else:
    raise SystemExit(f"python package path unavailable: {package_name}")
PY
}

# Each manifest entry is: <import-package> <overlay-source> <target-relative-path>.
while read -r package_name source_rel target_rel; do
    if [[ -z "${package_name}" || "${package_name}" == \#* ]]; then
        continue
    fi

    if [[ -z "${source_rel:-}" || -z "${target_rel:-}" ]]; then
        echo "invalid manifest entry for package ${package_name}" >&2
        exit 1
    fi

    source_path="${overlay_root}/${source_rel}"
    if [[ ! -f "${source_path}" ]]; then
        echo "overlay source not found: ${source_path}" >&2
        exit 1
    fi

    # Resolve the installed package first, then copy the overlay file onto the
    # expected module path so layout changes fail loudly during the image build.
    package_dir="$(resolve_package_dir "${package_name}")"
    target_path="${package_dir}/${target_rel}"
    if [[ ! -f "${target_path}" ]]; then
        echo "overlay target not found: ${target_path}" >&2
        exit 1
    fi

    cp "${source_path}" "${target_path}"
done < "${manifest}"