# AGENTS.md - AI Agent Guidelines for eduID Release Engineering

This document provides guidelines for AI coding agents working in the eduID release engineering repository.

Rule language in this document:
- **Must**: required for changes that are ready for review
- **Should**: the default approach unless there is a clear reason to do otherwise
- **May**: optional guidance

Unless noted otherwise, code snippets in this document are illustrative and may omit surrounding setup.

## Project Overview

This repository is the build and release orchestration layer for eduID.

It does not primarily implement application business logic. Its purpose is to:

- select which upstream revisions are included in a release
- export clean source snapshots from submodules
- build shared Python and frontend artifacts
- assemble runtime Docker images
- promote versioned images through testing, staging, and production

The main workflow is controlled by the top-level `Makefile`.

## Repository Boundaries

### Submodules

The directories under `build/repos/` are git submodules, not normal folders owned by this repository.

That means:

- changes inside `build/repos/eduid-backend`, `build/repos/eduid-front`, `build/repos/eduid-html`, and `build/repos/eduid-managed-accounts` belong to those repositories
- changes made inside a submodule must be committed in that submodule repository, not in `eduid-releng`
- this repository only tracks the submodule pointer, meaning the exact upstream commit to use

If a task changes both releng code and submodule code, treat them as separate commits in separate repositories.

### Generated Sources

`build/sources/` is generated content produced by `make -C build update` using `git archive` from the submodules.

Agents must not make manual edits under `build/sources/`.

If the exported content is wrong, fix the source repository or the export logic in `build/Makefile` instead.

## Key Build Entry Points

The main commands and files in this repository are:

- `make build_prep` to initialize and update submodules
- `make update_what_to_build` to move submodules to the intended upstream branch or revision
- `make dockers` to build the intermediate image and all runtime images
- `make VERSION=<version> dockers_tagpush` to push testing-tagged images
- `make VERSION=<version> staging_release` to promote testing images to staging
- `make VERSION=<version> production_release` to promote staging images to production

Important implementation files:

- `build/Makefile` for source export and intermediate build orchestration
- `build/build-js.sh` for frontend artifact creation
- `build/setup-venv.sh` for Python environment creation
- service-specific Dockerfiles under `prebuild/`, `webapp/`, `worker/`, `fastapi/`, `satosa_scim/`, `admintools/`, `html/`, and `vccs/`


## Validation Expectations

After making changes, use the narrowest validation that matches the modified area.

- For shell script changes, should run `bash -n` on the touched script.
- For Makefile changes, should use `make -n <target>` when a dry run is meaningful.
- For documentation-only changes, may validate with a focused `git diff` or `git status` check.
- For build logic changes, should prefer a targeted build-path check over a broad full build when a narrower check can falsify the change.

## Commit Policy

All commits must be signed.

If commit signing fails for any reason, stop the commit process and fix the signing setup before creating the commit.

## Change Scope

Agents should keep changes narrowly scoped to the releng problem being solved.

- Do not edit unrelated notes or analysis documents unless the task explicitly calls for it.
- Do not rewrite generated files to match preferred formatting.
- Do not convert a submodule change into a releng-only change by editing exported sources.

## Documentation Guidance

When adding releng-specific documentation, prefer top-level repository documentation or the `docs/` directory when the content is operational or policy-oriented.

Documentation should describe:

- what part of the release pipeline is affected
- whether the change belongs to releng or to an upstream submodule
- what validations or operational checks are expected