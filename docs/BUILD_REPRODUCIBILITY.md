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

## TODO: Backend

This section is intentionally left as a placeholder for the backend reproducibility work.

- TODO: document the backend reproducibility requirements after the backend build path is reviewed in the same way as the frontend path.
