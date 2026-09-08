# Runtime Image Contract

## Purpose

Summarize what each runtime image receives from releng and how it is built.

## Source Of Truth

- `images/*/Dockerfile`
- `images/*/Makefile`
- `images/*/start-*.sh`

## Shared Runtime Pattern

Most runtime images:

- start from `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}`
- copy backend source into `/opt/eduid/src`
- copy a service-specific virtual environment from `eduid-build:$VERSION`
- run a releng-owned startup script

## Image Roles

- `webapp`: main web application runtime
- `worker`: background jobs and Celery workers
- `fastapi`: FastAPI-based runtime
- `admintools`: administrative runtime with no single fixed command surface
- `satosa_scim`: SATOSA SCIM runtime with local package overlays
- `html`: static HTML and frontend delivery image
- `vccs`: Luna-backed runtime that builds its own Python environment in the final image

## Current Exceptions

- `html` does not follow the Python-service pattern
- `vccs` uses `FROM ${VCCS_LUNA_IMAGE_REF}` rather than the shared Debian base
- `satosa_scim` applies releng-owned overlays after copying the prebuilt venv

## Promotion Contract

Each image Makefile supports:

- local `docker` build
- `docker_tagpush` for testing-tag publication
- `tag_copypush` for promotion by retagging