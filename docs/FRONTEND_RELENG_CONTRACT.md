# Frontend Releng Contract

## Purpose

This document defines the current contract between eduID release engineering and the frontend source repositories as they are assembled by this repository today.

It describes what releng guarantees, what the frontend repositories must provide, and which current-state gaps still need to be treated as explicit exceptions instead of assumptions.

## Current Scope

The frontend release path currently spans three upstream repositories:

- `eduid-front`
- `eduid-managed-accounts`
- `eduid-html`

In the current releng implementation:

- the releng repository selects the upstream revisions through submodule pointers under `build/repos/`
- `build/Makefile` exports clean source snapshots into `build/sources/` with `git archive`
- `build/build-js.sh` installs dependencies and builds the JavaScript artifacts
- `images/html/Dockerfile` assembles the static delivery image by combining `eduid-html` content with the built frontend artifacts

The frontend artifacts are currently shipped through the `html` image. They are not copied into the Python service images.

## Releng Guarantees

For the frontend release path, releng currently guarantees all of the following:

### Clean source export

- Releng builds from exported source snapshots in `build/sources/`, not directly from the in-place submodule working trees.
- Releng records upstream provenance by writing `revision.txt` files for `eduid-front`, `eduid-managed-accounts`, and `eduid-html` during source export.

### Dependency installation policy

- Frontend release builds require a committed `package-lock.json` in the exported source tree.
- Frontend release builds use `npm ci --no-audit --no-fund`.
- Releng does not regenerate frontend lockfiles during artifact creation.

### Build commands and output locations

- For `eduid-front`, releng runs `npm run build-staging` and `npm run build-production` and copies `build/` into `/opt/eduid/eduid-front`.
- For `eduid-managed-accounts`, releng runs `npx vite build` and copies `dist/` into `/opt/eduid/eduid-managed-accounts`.
- For `eduid-html`, releng copies nginx configuration and static assets into the runtime image alongside the built frontend outputs.

### Runtime assembly

- The `html` image includes separate revision metadata for `eduid-html`, `eduid-front`, and `eduid-managed-accounts`.
- The `html` image is the current integration point for nginx configuration, static assets, and built frontend bundles.
- Release promotion retags previously built images; releng does not rebuild frontend artifacts during promotion from testing to staging or production.

## Frontend Repository Obligations

The frontend repositories must satisfy all of the following for the releng path to remain valid:

### Source ownership

- Application code, bundler configuration, routing behavior, and package selection remain owned by the upstream frontend repositories.
- Changes inside `build/repos/eduid-front`, `build/repos/eduid-managed-accounts`, and `build/repos/eduid-html` belong in those repositories, not as releng-only edits.
- Generated exports under `build/sources/` are not hand-edited.

### Dependency inputs

- Each frontend repository built by releng must commit its `package-lock.json`.
- `package-lock.json` must stay in sync with `package.json`.
- Release-oriented build paths in the frontend repositories should remain compatible with `npm ci` and must not depend on releng regenerating the lockfile.

### Build interface stability

- `eduid-front` must continue to provide the build scripts releng invokes today, or releng must be updated in the same change.
- `eduid-managed-accounts` must continue to produce a build output consumable from `dist/`, or releng must be updated in the same change.
- If asset paths, nginx assumptions, or integration points with `eduid-html` change, the owning repository and releng must be updated together.

### Toolchain declaration

- The frontend repositories should declare the Node/npm version contract needed for their builds.
- In the current repo state, `eduid-front` declares minimum Node/npm versions in `package.json`.
- In the current repo state, `eduid-managed-accounts` does not declare an equivalent `engines` contract yet and should add one.

## What Releng Does Not Guarantee

Releng does not currently guarantee any of the following:

- frontend unit or integration test execution as part of the releng build path
- automatic adaptation to renamed build scripts or changed output directories
- correctness of application-level routing, API behavior, or browser-side business logic
- a frontend-specific Node/npm pin that is versioned separately from the shared Debian-based prebuild image

## Releng Release Checklist

Before releasing the frontend path, confirm all of the following:

- [ ] `package-lock.json` is present for each frontend repository built by releng.
- [ ] `npm ci` succeeds from a clean exported source tree.
- [ ] The expected releng-invoked build scripts still exist and still produce the expected output directories.
- [ ] `eduid-html` still matches the asset layout produced by the frontend builds.
- [ ] Any frontend change that required releng assembly changes updated both sides of the interface in the same change set.

## Current-State Exceptions And Gaps

The current repository state still has a few frontend contract gaps that should be treated explicitly:

- Releng pins `uv` for the shared build image, but it does not yet expose a comparable first-class Node/npm pin in releng-owned version files.
- The current prebuild image obtains `npm` from the Debian package set, so the effective frontend toolchain is still coupled to the Debian base and package mirror state.
- `eduid-managed-accounts` currently lacks an explicit Node/npm `engines` declaration even though releng now expects a deterministic npm-based build path.

## Operational Checkpoints

When changing the frontend contract, the narrow releng checks should be:

- `bash -n build/build-js.sh`
- `make -n build`
- a focused frontend build-path validation in the owning repository when the build interface changes

Those checks do not replace frontend repository CI, but they do verify that the releng-side interface remains coherent.