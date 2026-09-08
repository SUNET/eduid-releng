# Architecture Overview

## Purpose

Describe what this repository owns and how it fits between upstream source repositories and deployable images.

## Scope

This page covers the releng repository itself. It does not document eduID application business logic.

## Audience

Maintainers, reviewers, and operators who need to understand the repo at a system level.

## Source Of Truth

- `Makefile`
- `build/Makefile`
- `images/*/Makefile`
- `images/*/Dockerfile`

## Current State

This repository is the release-engineering and image-assembly layer for eduID.

Its main responsibilities are:

1. Track which upstream revisions are included in a release through git submodules under `build/repos/`.
2. Export clean source snapshots into `build/sources/` with `git archive`.
3. Build shared Python and frontend artifacts in the intermediate `eduid-build:$VERSION` image.
4. Assemble runtime Docker images under `images/`.
5. Promote previously built images through `testing`, `staging`, and `production` tags.

The application code itself lives in upstream repositories, not in this releng repository.

## Key Boundaries

- `build/repos/*` are git submodules owned by other repositories.
- `build/sources/*` are generated exports and are not hand-edited.
- `images/` contains releng-owned runtime assembly logic.
- `versions/` contains releng-owned reviewed image input values.

## Main Flow

1. `make build_prep` initializes and updates submodules.
2. `make update_what_to_build` checks out the selected branch in each submodule.
3. `make dockers` builds `eduid-prebuild`, `eduid-build:$VERSION`, and each runtime image.
4. `make VERSION=<version> dockers_tagpush` publishes testing-tagged images.
5. `make VERSION=<version> staging_release` and `production_release` retag existing images rather than rebuilding them.

## Important Exception

Most Python service images copy a prebuilt virtual environment from the shared build image.

`vccs` is the main exception. It starts from a separate Luna client base and creates its Python environment in its own Dockerfile.

## Related Pages

- [build-pipeline.md](build-pipeline.md)
- [artifact-flow.md](artifact-flow.md)
- [repo-boundaries.md](repo-boundaries.md)