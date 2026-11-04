# eduID Release Engineering

Build and release orchestration for eduID.

This repository does not contain application code. It selects which upstream
revisions go into a release, builds shared Python and frontend artifacts from
clean source exports, assembles the runtime Docker images, and promotes those
images through **testing → staging → production** by retagging.

## Quick Start

Requirements: Git, GNU Make, a working Docker daemon, network access, and
registry credentials for publishing.

```bash
# Check out the upstream revisions recorded in this repository
make build_prep

# Build every runtime image locally
make VERSION=20261104T150000 dockers
```

Running `make` without a target prints a short help message.

Always pass an explicit `VERSION` and reuse it across build, publish, and
promotion commands. Without it, each `make` invocation generates a new UTC
timestamp.

## Upstream Sources

Upstream repositories are tracked as git submodules under `build/repos/`:

| Submodule | Content |
| --- | --- |
| [eduid-backend](https://github.com/SUNET/eduid-backend) | Python backend services |
| [eduid-front](https://github.com/SUNET/eduid-front) | Main frontend application |
| [eduid-managed-accounts](https://github.com/SUNET/eduid-managed-accounts) | Managed accounts frontend |
| [eduid-html](https://github.com/SUNET/eduid-html) | Static HTML, assets, and nginx config |

The release includes the submodule commits recorded in this repository. To move
every submodule to an upstream branch:

```bash
make update_what_to_build                               # origin/main
make BRANCH=origin/feature-branch update_what_to_build  # branch must exist in every submodule
```

This target runs `git pull` in this repository and commits each updated
submodule pointer. Configure commit signing beforehand. Commit failures are
ignored, so check `git status` and `git log --show-signature` afterward.
Pushes are always manual.

Changes to application code belong in the upstream repositories, not in
`build/repos/` or the generated `build/sources/` exports.

## How The Build Works

1. **`prebuild`** builds `eduid-prebuild` from Debian. It provides the build
   toolchain: Debian Python, native build dependencies, `uv`, and Node.js/npm
   copied from the official Node image.
2. **`build`** exports each submodule's committed `HEAD` into `build/sources/`
   with `git archive`, writes `revision.txt` metadata, and builds
   `eduid-build:<VERSION>`. Inside that image:
   - `build/setup-venv.sh` creates one virtualenv per Python service with `uv`
     and hash-locked backend requirements.
   - `build/build-js.sh` runs `npm ci` from committed lockfiles and builds both
     frontends.
3. **`runtime_common`** builds `eduid-runtime-common:<VERSION>`, the shared
   Debian runtime parent with the `eduid` user and common OS packages.
4. **Runtime images** copy the artifacts they need from `eduid-build:<VERSION>`
   onto their runtime base.

`make dockers` runs all of the above. Individual targets such as
`make VERSION=<version> webapp` also run the shared stages they depend on.

See [build pipeline](docs/architecture/build-pipeline.md) and
[artifact flow](docs/architecture/artifact-flow.md) for details.

## Runtime Images

| Image | Runtime base | Contents |
| --- | --- | --- |
| `webapp` | `eduid-runtime-common` | Backend source + `webapp` venv |
| `worker` | `eduid-runtime-common` | Backend source + `worker` venv |
| `fastapi` | `eduid-runtime-common` | Backend source + `fastapi` venv |
| `satosa_scim` | `eduid-runtime-common` | Backend source + `satosa_scim` venv with releng package overlays |
| `admintools` | `eduid-runtime-common` | Backend source + `admintools` venv |
| `html` | `eduid-runtime-common` | nginx, `eduid-html` content, and both frontend bundles |
| `vccs` | Luna client image | Backend source + shared `fastapi` venv |

`vccs` is the only image not based on `eduid-runtime-common`. It runs on a
separately reviewed Luna HSM client base, which must stay compatible with the
Debian-built `fastapi` virtualenv it copies.

Images are published to `<REGISTRY>/eduid/<image>`, where `REGISTRY` defaults to
`platform.sunet.se`.

## Releasing

```bash
VERSION=20261104T150000

make VERSION="$VERSION" dockers               # build locally
make VERSION="$VERSION" dockers_tagpush       # push :<VERSION>-testing
# ...validate testing...
make VERSION="$VERSION" staging_release       # retag testing -> staging
# ...validate staging...
make VERSION="$VERSION" production_release    # retag staging -> production
```

- Publishing and promotion always process all seven images, even if the build
  was restricted with `DOCKERS=...`.
- Promotion pulls, retags, and pushes existing registry images. It never
  rebuilds, so it can run on another authenticated host.
- Nothing is atomic: a failure can leave some images updated and others not.
  Check the registry before retrying.
- **`admintools` uses unversioned tags** (`testing`, `staging`, `production`).
  `VERSION` does not select which `admintools` image gets promoted, and older
  versions cannot be restored by version. Check its source tag separately.

See [promotion](docs/operations/promotion.md) and
[rollback](docs/operations/rollback.md).

## Continuous Integration

The Forgejo workflow in `.forgejo/workflows/build-action.yaml` runs on every
branch push and executes:

```bash
make dockers dockers_tagpush REGISTRY=platform.sunet.se
```

with `DOCKER_BUILDKIT=0`. It builds the recorded submodule revisions and
publishes testing images only. Staging and production promotion are manual.
The legacy `.jenkins.yaml` job is disabled.

## Reviewed Inputs

Image inputs that releng reviews are defined under `versions/`:

| Variable | File | Selects |
| --- | --- | --- |
| `DEBIAN_VERSION` | `versions/base-images.mk` | Debian codename for prebuild and runtime images |
| `NODE_MAJOR` | `versions/build-toolchain.mk` | Node.js major for frontend builds |
| `VCCS_LUNA_IMAGE_REPO`, `VCCS_LUNA_IMAGE_TAG` | `versions/runtime-images.mk` | Luna client base for `vccs` |

These are mutable tags, not digest pins. The Debian release in
`VCCS_LUNA_IMAGE_TAG` must match `DEBIAN_VERSION`. `uv` is installed unpinned
from pip.

See [base image versioning](docs/policy/base-image-versioning.md) and
[version files](docs/reference/version-files.md).

## Repository Layout

```
├── Makefile             # Top-level orchestration
├── versions/            # Reviewed image input values
├── build/
│   ├── Makefile         # Source export and eduid-build image
│   ├── setup-venv.sh    # Python virtualenv builder
│   ├── build-js.sh      # Frontend builder
│   ├── repos/           # Git submodules (upstream-owned)
│   └── sources/         # Generated exports (never edit)
├── images/
│   ├── prebuild/        # Build toolchain image
│   ├── runtime_common/  # Shared Debian runtime parent
│   └── <service>/       # One directory per runtime image
├── docs/                # Architecture, operations, contracts, policy, ADRs
└── .forgejo/            # CI workflow
```

## Documentation

Start at [docs/index.md](docs/index.md). Frequently used pages:

- [Makefile operator manual](docs/reference/makefile-operator-manual.md): every target and variable
- [Command workflows](docs/operations/workflows.md): local, CI, and release commands
- [Backend](docs/contracts/backend-releng-contract.md) and
  [frontend](docs/contracts/frontend-releng-contract.md) contracts: what releng expects from upstream
- [Troubleshooting](docs/operations/troubleshooting.md)

The code is the source of truth. If the documentation disagrees with the
Makefiles, scripts, or Dockerfiles, trust the code and fix the docs.
