# Build Reproducibility

## What Build Reproducibility Means

Build reproducibility means that the build result is determined by reviewed and versioned inputs rather than by whatever happens to be available at build time.

In practical terms, a build is reproducible when the same source revisions, the same dependency lock state, and the same build toolchain inputs produce the same artifacts every time the build is repeated.

That requirement matters because it gives release engineering a way to answer a basic question with confidence: if a release is rebuilt from the same approved inputs, do we get the same result or not?

For this repository, reproducibility depends on controlling at least these inputs:

- the exact source revision for each repository included in the release
- the exact frontend dependency graph used to build browser assets
- the exact Python dependency set used to build runtime environments
- the exact container base images and OS package inputs used during image creation
- the exact build toolchain version family that interprets the lockfiles and source trees

When those inputs are fixed and reviewed, a repeated build should not silently change because a registry served a newer package, a lockfile was regenerated during the build, or a base image drifted underneath the same source tree.

## Frontend Scope

The frontend part of the releng build currently covers these repositories:

- `eduid-front`
- `eduid-managed-accounts`

The releng repository now enforces the correct high-level contract for frontend dependency installation in `build/build-js.sh`:

- release builds require a committed `package-lock.json`
- release builds use `npm ci --no-audit --no-fund`
- release builds no longer regenerate lockfiles during artifact creation

That releng-side contract is necessary, but the frontend repositories themselves must also follow the same rules in their own local build paths and CI jobs.

## TODO: Frontend

The following work should be completed in `eduid-front` and `eduid-managed-accounts` to fully satisfy frontend build reproducibility:

- Keep `package-lock.json` committed and updated whenever `package.json` changes.
- Ensure every release-oriented build path uses `npm ci --no-audit --no-fund` rather than `npm install`.
- Ensure no CI workflow, helper script, or local release path runs `npm i --package-lock-only` during artifact creation.
- Keep `clean` targets limited to generated outputs and `node_modules`, and never delete the committed lockfile.
- Run CI and release builds from a clean checkout so the lockfile and tracked sources are the only dependency inputs.
- Fail CI immediately when `package-lock.json` is missing or out of sync with `package.json`.
- Audit repository workflows and helper scripts for fallback dependency installation paths that still use `npm install`.
- Keep the Node/npm toolchain contract explicit and documented in both repositories.
- Tighten the toolchain contract in `eduid-managed-accounts`, which currently needs a clearer explicit Node/npm version policy.
- Verify that the same locked inputs produce identical frontend build outputs across repeated runs in CI.

## Backend Scope

The Python part of the releng build currently centers on the backend dependency lockfiles exported from `eduid-backend` and installed by releng into per-service virtual environments.

The current releng-owned contract is split across these paths:

- `build/setup-venv.sh` creates virtual environments for `admintools`, `fastapi`, `satosa_scim`, `webapp`, and `worker`.
- `build/setup-venv.sh` installs from `build/sources/eduid-backend/requirements/${NAME}_requirements.txt` when that file exists, or falls back to `requirements/main.txt`.
- `eduid-backend/requirements/*.txt` are generated with `uv pip compile --generate-hashes`, so the Python dependency graph is version-pinned and hash-pinned at the requirements-file level.
- `vccs/Dockerfile` currently performs its own separate Python virtualenv creation and dependency installation rather than reusing the shared releng helper.

That means the Python dependency set is substantially better controlled than before, but the full Python build is still not reproducible end-to-end.

## Current Backend Findings

The Python side is only partially reproducible today.

What is already controlled:

- The backend dependency inputs are checked into version control as compiled lockfiles under `eduid-backend/requirements/`.
- Those lockfiles include exact package versions and hashes, which is the correct foundation for reproducible Python dependency installation.
- The releng build consistently installs from those committed lockfiles with `pip install --require-hashes` rather than resolving from `pyproject.toml` during image creation.
- The runtime start scripts no longer install optional packages from `dev-extra-modules.txt`, so mounted developer sources do not change the installed Python dependency set at process start.

What is still mutable:

- `build/setup-venv.sh` runs `pip install --upgrade pip wheel`, so the installer toolchain changes over time even when the source tree and requirements files do not.
- `vccs/Dockerfile` duplicates the same mutable pattern by creating a virtualenv and upgrading `pip` and `wheel` during its own image build path.

The result is that repeated builds from the same git revisions can still produce different Python environments because the Python installer toolchain is not fully fixed. The broader container base image and apt package drift is a separate repo-wide issue covered below.

## TODO: Backend

The following releng work should be completed to make the Python side reproducible in practice rather than only at the lockfile level:

- Stop upgrading `pip` and `wheel` to whatever is current at build time; either rely on a pinned base toolchain or install exact tool versions from a reviewed constraint.
- Consolidate the `vccs` Python install path onto the same reproducibility contract as the other services.
- Add a focused CI check that rebuilds the Python environment twice from the same inputs and compares the resulting installed package set and image digest-relevant contents.

## TODO: Shared Container Inputs

The following reproducibility work is shared across the repository and should not be treated as a backend-only issue:

- Pin container base images by digest rather than floating tags such as `debian:stable`.
- Replace floating Debian package resolution with a snapshot or otherwise version-pinned apt input so `dist-upgrade` does not change rebuild results.
- Review the common build and runtime Dockerfiles so the same container input policy applies consistently across Python and frontend image paths.
