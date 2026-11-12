# eduID Release Engineering

This repository manages the build and release process for eduID Docker images.

## Overview

The release engineering workflow builds Docker images from multiple eduID source repositories and manages their promotion through testing, staging, and production environments.

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
| `vccs` | VCCS service (built on the Luna HSM client image) |

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
```

### Release Workflow

The release process follows a promotion model: **testing → staging → production**

#### 1. Build and Push to Testing

```bash
make dockers
make VERSION=<version> dockers_tagpush
```

This builds images and pushes them with a `-testing` tag suffix.

The Forgejo workflow `.forgejo/workflows/build-action.yaml` is configured to run
`make dockers dockers_tagpush` on every branch push (not on tags).

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
├── prebuild/         # Base image with common dependencies
├── build/            # Build image and source export
│   └── repos/        # Git submodules
├── webapp/           # Webapp Docker image
├── worker/           # Worker Docker image
├── fastapi/          # FastAPI Docker image
├── satosa_scim/      # SATOSA SCIM Docker image
├── admintools/       # Admin tools Docker image
├── html/             # Static HTML Docker image
├── vccs/             # VCCS Docker image
├── labels.mk         # Source-commit image labels, included by the image Makefiles
└── tools/            # Helper scripts (whats-deployed)
```

## Docker Registry

Images are pushed to `platform.sunet.se/eduid/` (the `REGISTRY` variable in the image Makefiles).

## What is deployed?

Image tags are build timestamps (`20261021T090739-production`). Each image also
records the source commits it was built from as Docker labels, written by
`labels.mk` at build time:

| Label | Value |
|-------|-------|
| `se.sunet.eduid.backend-rev` | `eduid-backend` commit |
| `se.sunet.eduid.front-rev` | `eduid-front` commit |
| `se.sunet.eduid.html-rev` | `eduid-html` commit |
| `se.sunet.eduid.managed-accounts-rev` | `eduid-managed-accounts` commit |
| `se.sunet.eduid.version` | the build `VERSION` |

The commits are read from `/build/submodules.txt` in the `eduid-build:<VERSION>`
image that the runtime images copy their sources from, so rebuilding a single
image after the submodules moved still labels the sources it really contains. Images built before the labels were added have none.

```bash
docker image inspect --format '{{json .Config.Labels}}' platform.sunet.se/eduid/webapp:<tag>
```

`tools/whats-deployed` answers "which commits are in staging and production?".
It reads the current image tags from `eduid_versions.yaml` in `eduid-cosmos`
(staging) and `eduid-ops` (production), then finds the source commits:

1. from the image labels, if the image is available locally (`--pull` runs
   `docker pull` for missing ones), or otherwise
2. from the gitlinks of the last releng commit made at or before the build time
   in the version (approximate, derived from git only).

It prints each commit with date, subject and a GitHub link, and says per version
whether the result was read from the image or derived from git.

```bash
tools/whats-deployed                    # latest version in staging and production
tools/whats-deployed production --pull  # pull the images to read their labels
tools/whats-deployed 20261021T090739    # one specific version
tools/whats-deployed --all              # every version in use, not just the latest
tools/whats-deployed -h                 # all options
```

The other checkouts are expected next to this one (`../eduid-ops`,
`../eduid-cosmos`, `../eduid-backend`, `../eduid-front`, `../eduid-html`,
`../eduid-managed-accounts`); use `--ops`, `--backend` etc. to point elsewhere.
Missing checkouts are reported and the SHAs are still printed. Nothing is
fetched unless `--fetch` is given, and `--dry-run` shows what `--fetch` and
`--pull` would do. Tags that nothing references (removed services, or ones
deployed another way such as the navet service) are ignored.
