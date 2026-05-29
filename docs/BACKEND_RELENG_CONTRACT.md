# Backend Releng Contract

## Purpose

This document defines the current contract between eduID release engineering and the backend source repository as it is packaged by this repository today.

It focuses on the Python service build path, the runtime images that consume it, and the current exceptions that still keep the backend path from being fully uniform.

## Current Scope

The backend release path currently centers on `eduid-backend` and feeds these runtime images:

- `webapp`
- `worker`
- `fastapi`
- `admintools`
- `satosa_scim`
- `vccs`

In the current releng implementation:

- the releng repository selects the `eduid-backend` revision through the submodule pointer under `build/repos/eduid-backend`
- `build/Makefile` exports a clean source snapshot into `build/sources/eduid-backend`
- `build/setup-venv.sh` builds the shared Python virtualenv artifacts for `webapp`, `worker`, `fastapi`, `admintools`, and `satosa_scim`
- most runtime Dockerfiles copy those prebuilt virtualenvs into the final service image
- `images/vccs/Dockerfile` remains a separate runtime-path exception and builds its own virtualenv inside the final image

## Releng Guarantees

For the backend release path, releng currently guarantees all of the following:

### Clean source export and provenance

- Releng exports `eduid-backend` with `git archive` into `build/sources/eduid-backend`.
- Releng records backend provenance in `build/sources/eduid-backend/revision.txt` and copies that metadata into runtime images.

### Shared Python build path

- Releng creates service virtualenvs under `/opt/eduid/<name>` with `uv venv`.
- Releng installs Python dependencies with `uv pip install --require-hashes` against the SUNET package index.
- Releng uses the shared helper `build/setup-venv.sh` for `admintools`, `fastapi`, `satosa_scim`, `webapp`, and `worker`.
- Releng pins the shared `uv` tool version in `versions/build-toolchain.mk` and installs that exact release in the prebuild image.

### Dependency input selection

- Releng first looks for `build/sources/eduid-backend/requirements/<service>_requirements.txt`.
- If a service-specific requirements file does not exist, releng falls back to `build/sources/eduid-backend/requirements/main.txt`.
- In the current repo state, service-specific lockfiles exist for `fastapi`, `satosa_scim`, `webapp`, and `worker`.
- In the current repo state, `admintools` falls back to `main.txt` because there is no dedicated `admintools_requirements.txt`.

### Runtime assembly

- `webapp`, `worker`, `fastapi`, `admintools`, and `satosa_scim` copy backend source plus a releng-built virtualenv into the runtime image.
- `satosa_scim` also applies releng-owned overlays from `images/satosa_scim/patches/`.
- Releng pins the shared Debian base release name in `versions/base-images.mk` for the Debian-based image paths.
- Releng pins the reviewed VCCS Luna image tag and digest in `versions/runtime-images.mk` for the separate `vccs` runtime base.

## Backend Repository Obligations

The backend repository must satisfy all of the following for the releng path to remain valid:

### Source ownership

- Application code, Python dependency declarations, generated requirements files, and service-specific entrypoints remain owned by `eduid-backend`.
- Changes inside `build/repos/eduid-backend` belong in the upstream repository, not as releng-only edits.
- Generated exports under `build/sources/eduid-backend` are not hand-edited.

### Dependency inputs

- The backend repository must commit the generated requirements files releng installs from.
- Those requirements files must remain compatible with `uv pip install --require-hashes`.
- If a service requires a distinct dependency set, the backend repository should provide a dedicated `<service>_requirements.txt` instead of relying on releng-specific workarounds.

### Build interface stability

- The backend source layout copied into runtime images must remain compatible with the current startup scripts, or releng must be updated in the same change.
- If a service needs a new virtualenv layout, startup command, or requirements filename, the upstream change and releng change must land together.
- Changes that affect `satosa_scim` overlays or `vccs` startup behavior require explicit releng review because those paths already contain releng-owned integration logic.

## What Releng Does Not Guarantee

Releng does not currently guarantee any of the following:

- that all backend services use a single uniform runtime build path
- that runtime images are fully reproducible at the Debian package layer
- that development-only startup hooks leave the built runtime environment unchanged
- that every service has a dedicated per-service requirements lockfile

## Releng Release Checklist

Before releasing the backend path, confirm all of the following:

- [ ] The committed requirements inputs are present, compatible with `--require-hashes`, and install successfully in the releng build path.
- [ ] No backend source layout change breaks a runtime Dockerfile or startup script without a matching releng update.
- [ ] No service now depends on packages that are only supplied through development-only startup mutation.
- [ ] Any further `vccs` divergence from the shared Python contract was an explicit releng decision.

## Current-State Exceptions And Gaps

The current repository state still has a few backend contract exceptions that should remain explicit:

- `vccs` builds its virtualenv inside the final runtime image instead of reusing `build/setup-venv.sh`.
- `images/vccs/Dockerfile` still falls back from `fastapi_requirements.txt` to `main.txt` if the first install attempt fails.
- `webapp`, `worker`, `fastapi`, and the delegated FastAPI startup path in `vccs` support `dev-extra-modules.txt`, which can mutate the Python environment at container startup in developer-mode setups.
- The Debian package layer is still mutable because the Dockerfiles run `apt-get update` and `apt-get dist-upgrade` against live package mirrors at build time.
- `admintools` still relies on `main.txt` rather than a dedicated service requirements file.

## Operational Checkpoints

When changing the backend contract, the narrow releng checks should be:

- `bash -n build/setup-venv.sh`
- `make -n build`
- a focused validation of the affected Dockerfile or startup script when the runtime interface changes

Those checks do not replace backend repository CI, but they do verify that the releng-side packaging contract remains coherent.