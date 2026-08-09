# eduID Release Engineering

This repository manages the build and release process for eduID Docker images.

## Overview

The release engineering workflow builds Docker images from multiple eduID source repositories and manages their promotion through testing, staging, and production environments.

## Current Status

- The active CI path is the Forgejo workflow in `.forgejo/workflows/build-action.yaml`, which still builds and pushes with `DOCKER_BUILDKIT=0`.
- Frontend release builds now require committed `package-lock.json` files and use `npm ci --no-audit --no-fund` in `build/build-js.sh`.
- The shared Python build helper now creates service virtualenvs against the image-provided `python3`, installs locked backend requirements, bootstraps `setuptools`, and then installs the exported `eduid-backend` source package into each service virtualenv.
- Shared Debian base-image review lives in `versions/base-images.mk`, while the separate VCCS Luna base is reviewed through the tag-plus-digest pair in `versions/runtime-images.mk`.
- `webapp`, `worker`, `fastapi`, `satosa_scim`, and `admintools` reuse the shared Python build helper; `vccs` remains the main exception and still creates its runtime virtualenv in its own Dockerfile.

### Must TODO In Upstream Frontends

- `eduid-front` must stop deleting `package-lock.json` in its upstream `Makefile`, must require the lockfile to already exist, and must use `npm ci --no-audit --no-fund` instead of `npm install` so releng can build from committed frontend dependency inputs.
- `eduid-managed-accounts` must make the same upstream `Makefile` changes for `package-lock.json` handling and `npm ci`, for the same reason.
- Those changes belong in the upstream submodule repositories, not in `build/sources/`.

Use this upstream `Makefile` pattern in both frontend repositories:

```make
clean:
	rm -f build/*
	rm -rf node_modules

package-lock.json:
	test -f package-lock.json

node_modules: package-lock.json
	npm ci --no-audit --no-fund
	touch node_modules
```

### Submodules

Source code is included via git submodules:

- [eduid-backend](https://github.com/SUNET/eduid-backend) - Python backend services
- [eduid-front](https://github.com/SUNET/eduid-front) - Frontend application
- [eduid-html](https://github.com/SUNET/eduid-html) - Static HTML/assets
- [eduid-managed-accounts](https://github.com/SUNET/eduid-managed-accounts) - Managed accounts frontend

### Docker Images

The following Docker images are built:

| Image | Description |
|-------|-------------|
| `webapp` | Web application server |
| `worker` | Background worker processes |
| `fastapi` | FastAPI-based services |
| `satosa_scim` | SATOSA SCIM integration |
| `admintools` | Administrative tools |
| `html` | Static HTML content |
| `vccs` | VCCS image with separate Luna-backed runtime path |

## Usage

### Initial Setup

```bash
# Initialize submodules
make build_prep
```

### Building Docker Images

```bash
# Update submodules to latest upstream and build all images
make update_what_to_build
make dockers

# Build with a specific version
make VERSION=20260115T120000 dockers

# Build individual images
make webapp
make worker
make fastapi
make vccs
```

### Version Pins

The repository separates shared base image pins and service-specific runtime image pins.

You can inspect and refresh them with:

```bash
make show-base-image-versions
make check-base-image-versions
make update-base-image-versions
make show-runtime-image-versions
make check-runtime-image-versions
make update-runtime-image-versions
```

The base image helper checks:

- `DEBIAN_VERSION` against Debian `stable`'s current codename
- `DEBIAN_DIGEST` against the resolved Docker Hub manifest digest for that reviewed codename

The runtime image helper checks:

- `VCCS_LUNA_IMAGE_TAG` against the latest stable numeric `luna-client` tag in `docker.sunet.se`
- `VCCS_LUNA_IMAGE_DIGEST` against the resolved manifest digest for that reviewed tag

### Release Workflow

The release process follows a promotion model: **testing → staging → production**

#### 1. Build and Push to Testing

```bash
make dockers
make VERSION=<version> dockers_tagpush
```

This builds images and pushes them with a `-testing` tag suffix.

#### 2. Promote to Staging

```bash
make VERSION=<version> staging_release
```

Re-tags images from `-testing` to `-staging`.

#### 3. Promote to Production

```bash
make VERSION=<version> production_release
```

Re-tags images from `-staging` to `-production`.

### Building from a Specific Branch

```bash
make BRANCH=origin/feature-branch update_what_to_build
make dockers
```

## Directory Structure

```
├── Makefile          # Main build orchestration
├── versions/         # Reviewed image pins and related policy notes
├── build/            # Build image and source export
│   └── repos/        # Git submodules
├── images/           # Runtime image implementations
│   ├── prebuild/     # Base image with common dependencies
│   ├── webapp/       # Webapp Docker image
│   ├── worker/       # Worker Docker image
│   ├── fastapi/      # FastAPI Docker image
│   ├── satosa_scim/  # SATOSA SCIM Docker image
│   ├── admintools/   # Admin tools Docker image
│   ├── html/         # Static HTML Docker image
│   └── vccs/         # VCCS Docker image
```

## Docker Registry

The service Makefiles default to `platform.sunet.se/eduid/<image>`.

The active Forgejo workflow also publishes with `REGISTRY=platform.sunet.se`.
