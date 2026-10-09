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
setup, then supervises `/start-fastapi.sh` for VCCS and `/start-pyeleven.sh` for
the standalone pyeleven service. Both use the shared Debian-backed FastAPI venv
and run their Gunicorn workers as `eduid`. If either service exits, the wrapper
stops the other and exits nonzero; container termination is forwarded to both.

Pyeleven defaults to five workers on port `8000`, alongside VCCS on `8080`.
`PYELEVEN_ARGS` and `PYELEVEN_PORT` override those defaults; Gunicorn must remain
in the foreground. `images/vccs/luna-pyeleven/entrypoint.sh` is an unmodified
copy of upstream's entrypoint at commit
`1cc745608311750c3c95da103bc77e9004817d6c`:
https://platform.sunet.se/keyforge/docker-luna-pyeleven/src/commit/1cc745608311750c3c95da103bc77e9004817d6c/entrypoint.sh.
Keep this file byte-identical to the selected upstream revision. Releng-specific
venv activation and file permissions belong in `start-pyeleven.sh`; worker user,
working directory and control socket belong in `pyeleven-gunicorn.conf.py`.

Upstream generates `/config.py` at startup with `DEBUG = True`, the Luna library
path, and the interpolated `PKCS11PIN`. The wrapper prepares the file as
`root:eduid` with mode `0640` and rejects double quotes, backslashes and line
breaks in the PIN because upstream does not escape them. Supplied launcher
arguments run that command from `/tmp` instead of starting pyeleven.
The PIN is not embedded in the image or printed by the launcher, but is present
in the generated runtime configuration file. The health
check requires both pyeleven `/info` and VCCS `/status/healthy`; it does not
verify HSM connectivity or a signing operation.

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