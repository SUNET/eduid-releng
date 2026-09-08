# Build Operations

## Purpose

Document the operator-facing commands for preparing sources and building images.

## Audience

Operators and maintainers running releng builds locally or in automation.

## Source Of Truth

- `Makefile`
- `build/Makefile`

## Main Commands

### Initialize submodules

```bash
make build_prep
```

### Update what will be built

```bash
make update_what_to_build
make BRANCH=origin/<branch> update_what_to_build
```

### Build all runtime images

```bash
make dockers
make VERSION=<version> dockers
```

### Build a single image

```bash
make webapp
make worker
make fastapi
make satosa_scim
make admintools
make html
make vccs
```

## What Happens

`make dockers` runs:

1. `build_prep`
2. `prebuild`
3. `build`
4. each runtime image target in `$(DOCKERS)`

## Required Inputs

- Docker available locally
- submodules initialized
- backend and frontend source revisions present under `build/repos/`

## Current Constraints

- frontend release builds fail if `package-lock.json` is missing in exported sources
- shared Python builds require `uv` and `python3` in the prebuild image
- `vccs` requires `VCCS_LUNA_IMAGE_TAG`

## Useful Checks

```bash
make -n dockers
bash -n build/build-js.sh
bash -n build/setup-venv.sh
```