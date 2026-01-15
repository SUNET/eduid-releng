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
└── html/             # Static HTML Docker image
```

## Docker Registry

Images are pushed to `docker.sunet.se/eduid/`.
