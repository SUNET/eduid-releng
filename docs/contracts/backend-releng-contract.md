# Backend Releng Contract

## Purpose

Define the current interface between releng and `eduid-backend`.

## Source Of Truth

- `build/setup-venv.sh`
- `build/Makefile`
- `images/webapp/Dockerfile`
- `images/worker/Dockerfile`
- `images/fastapi/Dockerfile`
- `images/admintools/Dockerfile`
- `images/satosa_scim/Dockerfile`
- `images/vccs/Dockerfile`

## What Releng Expects From eduid-backend

- a buildable source tree under `src/`
- dependency lockfiles under `requirements/`
- `main.txt` as the general fallback requirements set
- service-specific requirements files when a service needs its own dependency surface
- project metadata that `uv venv --project` and `uv pip install --no-build-isolation` can use

## What Releng Does

For shared Python services releng:

1. exports `eduid-backend` into `build/sources/eduid-backend`
2. creates a service venv under `/opt/eduid/<service>`
3. installs from `requirements/<service>_requirements.txt` when present, else `requirements/main.txt`
4. installs `setuptools` into the target venv
5. installs the exported backend project into that venv with `--no-deps --no-build-isolation`

## Services Using The Shared Contract

- `webapp`
- `worker`
- `fastapi`
- `admintools`
- `satosa_scim`

## Current Exception

`vccs` uses exported backend sources and requirements, but it does not reuse the shared helper end to end. It rebuilds its service environment in `images/vccs/Dockerfile`.

## What Releng Does Not Guarantee

- backend application correctness
- automatic adaptation to renamed requirement files
- runtime parity if upstream changes Python requirements beyond what the current image bases provide