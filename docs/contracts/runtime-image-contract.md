# Runtime Image Contract

## Purpose

Summarize what each runtime image receives from releng and how it is built.

## Source Of Truth

- `images/*/Dockerfile`
- `images/*/Makefile`
- `images/*/start-*.sh`

## Shared Runtime Pattern

Most runtime images:

- start from `eduid-runtime-common:$VERSION`
- copy backend source into `/opt/eduid/src`
- copy a service-specific virtual environment from `eduid-build:$VERSION`
- run a releng-owned startup script

The shared `runtime_common` parent is the layer that starts from
`debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` and provides the common operating
system packages, the `eduid` user and group, and the standard runtime
directories.

## Image Roles

- `webapp`: main web application runtime
- `worker`: background jobs and Celery workers
- `fastapi`: FastAPI-based runtime
- `admintools`: administrative runtime with no single fixed command surface
- `satosa_scim`: SATOSA SCIM runtime with local package overlays
- `html`: static HTML and frontend delivery image
- `vccs`: Luna-backed runtime that copies the shared FastAPI environment

## Current Exceptions

- `html` does not follow the Python-service pattern
- `vccs` uses `FROM ${VCCS_LUNA_IMAGE_REF}` rather than the shared Debian base
- `satosa_scim` applies releng-owned overlays after copying the prebuilt venv

VCCS installs Debian runtime Python, `curl`, and `xmlsec1` in its Luna-based
image. Base changes must preserve compatibility with the copied FastAPI venv:
validate Python imports, native-library resolution, and Luna certificate setup.

## Shared FastAPI Launcher

FastAPI and VCCS both copy `images/fastapi/start-fastapi.sh` into their images
as `/start-fastapi.sh`. VCCS first runs its own `/start-vccs.sh` wrapper for Luna
setup, then delegates to that shared launcher.

Only VCCS uses `images/` as the Docker build context and selects its Dockerfile
explicitly. FastAPI retains its `images/fastapi/` context. For direct VCCS
builds from the repository root, use
`docker build -f images/vccs/Dockerfile ... images/`; retain the required build
arguments.

## Promotion Contract

Each image Makefile supports:

- local `docker` build
- `docker_tagpush` for testing-tag publication
- `tag_copypush` for promotion by retagging