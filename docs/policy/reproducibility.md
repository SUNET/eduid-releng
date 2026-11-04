# Reproducibility Policy

## Purpose

Capture the current reproducibility posture of the releng repository.

## Source Of Truth

- `build/build-js.sh`
- `build/setup-venv.sh`
- `images/prebuild/Dockerfile`
- `images/*/Dockerfile`
- `versions/base-images.mk`
- `versions/runtime-images.mk`

## What Is Controlled Today

- source revisions are materialized through submodules and exported with `git archive`
- frontend release builds require committed lockfiles
- frontend installs use `npm ci --ignore-scripts --no-audit --no-fund`
- `eduid-front` shares its installation policy through a committed `.npmrc` and
  uses Git-independent cleanup, staging, and production npm commands in CI and releng
- frontend JavaScript cache-busting query strings retain compilation hashes,
  which can vary across build environments; CI checks compilation but does not
  compare outputs from repeated builds
- backend dependency installation uses `uv pip install --require-hashes`
- Debian-based images use a reviewed codename in `DEBIAN_VERSION`
- `vccs` uses a reviewed `VCCS_LUNA_IMAGE_TAG`

## What Is Still Mutable

- release input selection is still branch-driven
- frontend Node image tags remain mutable; upstream `.nvmrc` selection controls
  development and CI, not releng's release toolchain;
  locked dependencies alone do not guarantee byte-identical frontend artifacts
- Debian image codename tags are mutable and are not digest-pinned
- `uv` is installed from `pip` without a releng pin
- `build/setup-venv.sh` installs `setuptools` separately into the target venv
- Dockerfiles still use live `apt-get update` and `apt-get dist-upgrade`
- `vccs` uses a separate Luna runtime base that must remain compatible with the
  copied shared FastAPI venv
- the active CI workflow still sets `DOCKER_BUILDKIT=0`

## Current Rule

When tightening reproducibility, prefer changes that move floating inputs into explicit review points owned by releng.

## Related Pages

- [../policy/base-image-versioning.md](base-image-versioning.md)
- [../policy/supply-chain-security.md](supply-chain-security.md)