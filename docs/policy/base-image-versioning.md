# Base Image Versioning Policy

## Purpose

Define the project's operating-system and Python interpreter policy, and document
where releng-owned image input review points live.

The original project baseline is recorded in
[ADR 0000](../adr/0000-use-debian-stable-and-debian-provided-python.md).
This policy describes its operational application and review points.

## Source Of Truth

- `versions/base-images.mk`
- `versions/runtime-images.mk`
- `scripts/update-base-image-versions.sh`
- `images/prebuild/Dockerfile`
- `build/setup-venv.sh`

## Debian Stable Baseline

Debian stable is the project baseline for build and runtime images. Any exception,
including an externally supplied service base, must be explicitly reviewed and
documented.

Track Debian stable through a reviewed release codename in `DEBIAN_VERSION`,
rather than relying on the floating `stable` tag to advance images automatically.
The shared base also uses `DEBIAN_DIGEST` to identify the reviewed image.
When a new Debian stable release becomes available, review the baseline update
and validate affected builds and services before adopting it.

## Python Interpreter Policy

Releng trusts Python supplied and maintained by Debian packages for the selected
stable release. Debian determines the Python version; releng does not independently
pin its minor version or replace package-managed Python files with an interpreter
copied from another image.

Use `uv` to manage virtual environments and Python dependencies, not to provide
interpreters. Set `UV_PYTHON_DOWNLOADS=never` and select the Debian interpreter,
avoiding any unrelated interpreter or virtual environment inherited through
`PATH` from an external base image.

This policy governs releng-managed Python environments; it does not redefine the
interpreter used by software bundled in externally supplied base images.
Accepting Debian's Python version does not override upstream application Python
requirements. Baseline updates must validate those requirements, environment
creation, dependency installation, and runtime behavior. Keep required runtime
Python packages installed when removing build-only dependencies.

See [ADR 0007](../adr/0007-use-uv-for-releng-python-environment-management.md)
for the environment-management decision.

## Shared Debian Base

The Debian-based build and runtime images use:

- `DEBIAN_VERSION`
- `DEBIAN_DIGEST`

from `versions/base-images.mk`.

These values are the current releng-owned review point for shared Debian image identity.

## VCCS Runtime Base

`vccs` uses `VCCS_LUNA_IMAGE_REPO` and `VCCS_LUNA_IMAGE_TAG` from
`versions/runtime-images.mk`. This selects the Luna client base from
`platform.sunet.se/keyforge/luna-pyeleven`, separately from the shared Debian base.

That selection is currently tag-based, not digest-based.

For a base substitution, validate the Make dry run, build the VCCS image, and
check that its Python venv survives package cleanup, Luna library dependencies
resolve, and client certificate generation succeeds. HSM connectivity requires
a separate check with deployment certificates and a configured HSM.

## Helper Targets

The root `Makefile` exposes:

- `show-base-image-versions`
- `check-base-image-versions`
- `update-base-image-versions`