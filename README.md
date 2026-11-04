# eduID Release Engineering

This repository manages the build and release process for eduID Docker images.

## Overview

The release engineering workflow builds Docker images from multiple eduID source repositories and manages their promotion through testing, staging, and production environments.

## Current Status

- The active CI path is the Forgejo workflow in `.forgejo/workflows/build-action.yaml`, which still builds and pushes with `DOCKER_BUILDKIT=0`. The legacy `.jenkins.yaml` job is disabled.
- Frontend release builds now require committed `package-lock.json` files and use `npm ci --ignore-scripts --no-audit --no-fund` in `build/build-js.sh`.
- The shared Python build helper now creates service virtualenvs against the image-provided `python3`, installs locked backend requirements, bootstraps `setuptools`, and then installs the exported `eduid-backend` source package into each service virtualenv.
- Shared Debian base-image review lives in `versions/base-images.mk`, while the separate VCCS Luna base is currently reviewed through `VCCS_LUNA_IMAGE_REPO` and `VCCS_LUNA_IMAGE_TAG` in `versions/runtime-images.mk`.
- `webapp`, `worker`, `fastapi`, `satosa_scim`, and `admintools` reuse the shared Python build helper; `vccs` copies the shared FastAPI virtualenv but uses a separate Luna-backed runtime base.

### Upstream Frontend Build Inputs

- Both frontend repositories preserve their committed `package-lock.json` files during cleanup.
- `eduid-front` uses `npm ci` in upstream CI and shares its installation policy through `.npmrc`, including strict engine enforcement and disabled installation scripts. Its npm commands build staging and production artifacts; `make buildtest` provides isolated local build checks.
- `eduid-managed-accounts` requires the existing lockfile and uses `npm ci --ignore-scripts --no-audit --no-fund` in its upstream `Makefile`.
- Frontend dependency and build changes belong in the upstream submodule repositories, not in `build/sources/`.

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

See the [Makefile operator manual](docs/reference/makefile-operator-manual.md) for every
top-level target, workflow examples, variable overrides, and operational cautions.
For task-oriented commands grouped by local environments, CI, and release steps,
see the [command workflows guide](docs/operations/workflows.md).

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

The configured Debian codename is defined by `DEBIAN_VERSION` in
`versions/base-images.mk`.

Debian image builds use that mutable codename tag without a digest pin.
Change `DEBIAN_VERSION` in `versions/base-images.mk` manually after reviewing
and validating a Debian major-release upgrade.

The VCCS runtime build reads its reviewed Luna base image from `versions/runtime-images.mk`:

- `VCCS_LUNA_IMAGE_REPO`
- `VCCS_LUNA_IMAGE_TAG`

The Debian release in `VCCS_LUNA_IMAGE_TAG` must match `DEBIAN_VERSION`,
because VCCS runs the FastAPI virtualenv built on the shared Debian base.

The frontend Node.js major is defined by `NODE_MAJOR` in
`versions/build-toolchain.mk`. The prebuild image imports Node.js and bundled
npm from the official Node image for that major and the shared Debian codename.

### Release Workflow

The release process follows a promotion model: **testing → staging → production**

#### 1. Build and Push to Testing

```bash
make VERSION=<version> dockers
make VERSION=<version> dockers_tagpush
```

Use the same explicit version for both commands. This builds images and pushes
them with a `-testing` tag suffix, except `admintools`, which uses the unversioned
`testing` tag.

#### 2. Promote to Staging

```bash
make VERSION=<version> staging_release
```

Re-tags images from `-testing` to `-staging`.
For `admintools`, the tags are `testing` and `staging` without a version prefix.

#### 3. Promote to Production

```bash
make VERSION=<version> production_release
```

Re-tags images from `-staging` to `-production`.
For `admintools`, the tags are `staging` and `production` without a version prefix.

### Building from a Specific Branch

```bash
make BRANCH=origin/feature-branch update_what_to_build
make dockers
```

## Directory Structure

```
├── Makefile          # Main build orchestration
├── .forgejo/         # Forgejo CI workflow
├── docs/             # Architecture, operations, contracts, policy, and ADRs
├── versions/         # Reviewed image pins and related policy notes
├── build/            # Build image and source export
│   ├── repos/        # Git submodules (upstream-owned)
│   └── sources/      # Generated git archive exports (do not edit)
├── images/           # Runtime image implementations
│   ├── prebuild/     # Base image with common dependencies
│   ├── runtime_common/ # Shared Debian runtime parent
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
