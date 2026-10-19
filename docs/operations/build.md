# Build Operations

## Purpose

Document the operator-facing commands for preparing sources and building images.

## Audience

Operators and maintainers running releng builds locally or in automation.

## Source Of Truth

- `Makefile`
- `build/Makefile`

## Main Commands

### Initialize submodules

```bash
make build_prep
```

### Update what will be built

```bash
make update_what_to_build
make BRANCH=origin/<branch> update_what_to_build
```

### Build all runtime images

```bash
make dockers
make VERSION=<version> dockers
```

### Build the shared runtime parent only

```bash
make runtime_common
make VERSION=<version> runtime_common
```

### Build a single image

```bash
make webapp
make worker
make fastapi
make satosa_scim
make admintools
make html
make vccs
```

## What Happens

`make dockers` runs:

1. `build_prep`
2. `prebuild`
3. `build`
4. `runtime_common` for each non-`vccs` runtime image target
5. each runtime image target in `$(DOCKERS)`

## Required Inputs

- Docker available locally
- submodules initialized
- backend and frontend source revisions present under `build/repos/`

## Current Constraints

- frontend release builds fail if `package-lock.json` is missing in exported sources
- shared Python builds require `uv` and `python3` in the prebuild image
- non-`vccs` runtime images inherit their common OS setup from `runtime_common`
- `vccs` requires `VCCS_LUNA_IMAGE_TAG`

## Frontend Toolchain Updates

The Node.js major is an explicit releng policy, not a value inferred from
upstream engine ranges or lockfiles. Changing it requires a reviewed policy
update and compatibility validation of both frontend projects. npm follows
the selected Node.js image's bundled version, without a separate major pin.

Releng selects the Node.js major through `NODE_MAJOR` in
`versions/build-toolchain.mk`. The prebuild Makefile combines it with
`DEBIAN_VERSION` from `versions/base-images.mk` to select the official
`docker.io/library/node:<major>-<debian>-slim` image, currently
`docker.io/library/node:24-trixie-slim`. No additional resolver image or host
Node.js installation is needed. The prebuild Dockerfile retains Debian as its
base and imports only Node.js and bundled npm, creating the `npm` and `npx`
command links locally. Debian provides system libraries and Python; the Debian
`npm` package is not installed. Prebuild creation checks that Node.js,
npm, and npx run. `build/build-js.sh` requires an exported lockfile and runs
`npm ci --ignore-scripts --no-audit --no-fund`, without a custom engine check
or explicit strict engine enforcement.

The Makefile uses `--pull` to fetch the latest published minor/patch for the
selected major and Debian variant. It does not search for an older compatible
release if the current image is incompatible with the frontend projects. Releng
maintainers own major-version updates and review of compatibility and security
results. APT does not update copied Node.js/npm; rebuild prebuild to refresh
them. Record the resolved image identity and printed tool versions in build
evidence: the moving tag can change toolchain versions between builds. An
explicit `NODE_IMAGE=<image:tag>` Make argument can reuse a recorded version
tag, though tags remain mutable without digest pins. Image scanning and update
review are operational requirements, not automated gates in this change.

Validate a candidate prebuild under a separate test tag before replacing
`eduid-prebuild:latest`: check architecture, shared libraries, Node.js/npm/npx,
and Python/uv. Scan the candidate with the approved image scanner and review
findings. In disposable clean copies of both upstream projects, run releng's
installation and build commands with strict engine checking, verify Linux
optional dependencies, and confirm lockfiles are unchanged. Upstream lockfile
or build fixes belong in the owning repositories; release validation must
ultimately use their committed inputs and normal source exports.

## Useful Checks

```bash
make -n dockers
bash -n build/build-js.sh
bash -n build/setup-venv.sh
```