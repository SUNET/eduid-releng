# Build Image Failure Matrix

## Scope

This note maps the current Python-service build path to the concrete failure modes caused by installer behavior, wheel availability, and floating Debian base-image inputs.

The current top-level path is:

1. `make dockers`
2. `prebuild` builds `eduid-prebuild`
3. `build` builds `eduid-build:$VERSION`
4. Runtime images consume artifacts from `eduid-build:$VERSION`

The Python-service images covered here are:

- `webapp`
- `worker`
- `fastapi`
- `satosa_scim`
- `vccs`

Two facts control most of the failure behavior:

- `eduid-backend` currently requires `Python ==3.13.*`.
- The Debian-based build and runtime Dockerfiles now pin a Debian release through `DEBIAN_VERSION`, but they still use mutable Debian package resolution through `apt-get update` and `apt-get dist-upgrade`.

## Shared Failure Categories

### Python version drift

If a floating base image moves to a Python minor version other than 3.13, dependency installation can fail when the installer evaluates the backend requirement metadata.

Typical failure surface:

- install-time resolver error
- package ignored because it requires a different Python version
- no compatible distribution found for the selected Python version

### Wheel availability drift

The releng path installs from hash-locked requirements files with `uv pip install --require-hashes`. That is better than floating resolution, but it still depends on compatible artifacts existing for the Python and platform combination present in the image at build time.

Typical failure surface:

- hash mismatch because the installer selects a different artifact than the lock expected
- no compatible wheel found for the current Python or platform
- fallback to source build

### Source-build dependency drift

When the selected environment cannot use a prebuilt wheel, packages may need to build from source. That makes the build sensitive to Debian package drift in compilers, headers, crypto libraries, XML libraries, image libraries, and Python development packages.

Typical failure surface:

- `Failed building wheel for ...`
- missing compiler, header, or linker dependency
- native extension compile or link failure

### Runtime ABI drift after build

Several runtime images copy prebuilt virtual environments from the shared build image into a separate runtime image. If the build-stage and runtime-stage Debian or Python inputs diverge enough, the copied environment can fail later even when the original install step succeeded.

Typical failure surface:

- interpreter path mismatch inside copied venv scripts
- import-time shared-library load failure
- startup failure when a native extension or linked dependency resolves against a different runtime ABI

## Image Matrix

| Image | How Python env is created | Where drift enters | Exact failure modes in current path | Failure point | Masked or hard failure |
| --- | --- | --- | --- | --- | --- |
| `webapp` | Shared venv built in `eduid-build`, then copied into runtime image | `eduid-prebuild` and the runtime image now pin the Debian release through `DEBIAN_VERSION`, but both stages still resolve Debian packages mutably at build time | Python minor drift can still fail locked install if the pinned Debian release eventually moves Python away from 3.13; wheel drift can force source builds for packages such as `cryptography`, `pillow`, `pyopenssl`, `pysaml2`, and `xhtml2pdf`; mutable Debian package resolution can still break the copied venv later through interpreter or shared-library mismatch | Usually during `build/setup-venv.sh`; sometimes only at container start | Mostly hard at build time, but copied-venv ABI problems can be delayed until runtime |
| `worker` | Shared venv built in `eduid-build`, then copied into runtime image | Same as `webapp` | Same install-time failures as `webapp`; smaller runtime package surface, but still exposed to copied-venv Python and shared-library mismatch between build image and runtime image when Debian packages drift within the pinned release | Usually during `build/setup-venv.sh`; sometimes at container start | Mostly hard at build time, delayed if runtime ABI changes surface only on startup or import |
| `fastapi` | Shared venv built in `eduid-build`, then copied into runtime image | Same as `webapp`, plus the fastapi lockfile contains a direct URL dependency for `pyhsm` | Python 3.13 mismatch can fail dependency resolution; wheel drift can force source builds; the direct GitHub zip dependency for `pyhsm` can fail during build backend execution or native dependency setup; copied-venv runtime mismatch can still surface after a successful build | During `build/setup-venv.sh` for install failures, or at container start for copied-venv/runtime ABI failures | Mostly hard at build time, with delayed runtime failures still possible |
| `satosa_scim` | Shared venv built in `eduid-build`, then copied into runtime image | Same as `webapp` | Same install-time Python and wheel drift issues as other shared-venv images; runtime image also depends on `xmlsec1`, so mutable Debian package resolution can still surface as import or execution failures around SAML/XML security tooling after build success | During `build/setup-venv.sh`, overlay application, or container runtime | Mostly hard at build time, with some delayed runtime failures tied to `xmlsec1` or linked libraries |
| `vccs` | Builds its own venv in the runtime Dockerfile instead of reusing the shared helper | Digest-pinned runtime base from `docker.sunet.se/luna-client:${VCCS_LUNA_IMAGE_TAG}@${VCCS_LUNA_IMAGE_DIGEST}`, mutable Debian packages via `dist-upgrade`, separate installer execution in the image itself | Python version drift can fail venv creation or locked install directly in the runtime Dockerfile; wheel drift can force source builds against the runtime image's package set; Debian build-dependency drift can break native builds; if `fastapi_requirements.txt` install fails, the Dockerfile falls back to `main.txt`, so a dependency failure can be converted into a successful but incomplete image missing fastapi-only dependencies | During `docker build` of `vccs` | Both: hard failure if both installs fail, masked failure if fallback to `main.txt` succeeds |

## Notes By Image

### `webapp`

`webapp` is sensitive to copied-venv drift because it installs in the shared build image and later runs in a separate Debian runtime image. Pinning the Debian release reduces one class of base-image drift, but mutable apt resolution still means a successful install in the build stage does not fully guarantee that the runtime image will have a matching Python and shared-library environment.

### `worker`

`worker` has the same structural risk as `webapp`, but with a smaller declared application surface. The main build-path risk is still Python minor drift and wheel or source-build drift in the shared venv stage.

### `fastapi`

`fastapi` is the most exposed shared-venv image because its lockfile includes a direct URL dependency for `pyhsm`. If the selected environment cannot consume available wheels cleanly, the build becomes sensitive to Python packaging backend behavior and native build prerequisites in the build image.

### `satosa_scim`

`satosa_scim` inherits the same shared-venv risks as the other copied-venv images and adds runtime sensitivity around XML security tooling. Debian package drift can therefore show up either during install or later when the container executes SAML-related operations.

### `vccs`

`vccs` is the most failure-prone image in the current path because it does not reuse the shared helper and does not fail fast on the first dependency-set error. Its `fastapi_requirements.txt || main.txt` fallback means a broken fastapi-specific install can become a wrong-but-built image instead of a clear build stop.

## What No Longer Applies

The older releng failure mode of upgrading `pip` and `wheel` to whatever is current at build time is not the active shared build path anymore. The shared helper now uses `uv pip install --require-hashes` with a releng-owned `uv` pin.

That means the current drift risk is no longer primarily installer-version drift. The active risk is:

- Python minor-version drift from floating base images
- wheel compatibility drift for the selected Python and platform
- Debian package drift affecting native builds and runtime ABI compatibility
- the separate and non-fail-fast `vccs` install path

## Practical Reading Of The Matrix

If a rebuild starts failing unexpectedly without a source change, the most likely first questions are:

1. Did the currently pinned Debian release move Python away from 3.13 or otherwise change relevant package behavior?
2. Did the available wheel set change for the current Python or Debian combination?
3. Did a package fall back to source build and hit a missing or changed system dependency from mutable apt inputs?
4. For `vccs`, did the build silently fall back from `fastapi_requirements.txt` to `main.txt`?

Those are the shortest paths from the current repo state to a real reproducibility or release failure.