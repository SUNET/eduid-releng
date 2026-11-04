# Makefile Operator Manual

## Name

`make` — select eduID source revisions, build Docker images, publish them, and
promote releases.

## Synopsis

Run commands from the repository root:

```sh
make [VARIABLE=value ...] [target ...]
```

With no target, `make` runs `all`, which prints brief help without building.
This manual covers every target in the [top-level Makefile](../../Makefile).
Delegated behavior is implemented in [build/Makefile](../../build/Makefile)
and the service Makefiles under [images/](../../images/).

## Prerequisites And Safety

- Use Git, GNU Make, and a working Docker CLI/daemon.
- Allow network access for submodule initialization, source updates, image pulls,
  and dependency downloads.
- Authenticate to the chosen registry before publishing or promoting images.
  The VCCS build also pulls its configured Luna base image.
- Review local changes before running source-selection commands.
  `update_what_to_build` pulls the releng repository and creates commits.
  Configure signed Git commits before using it; the recipe does not explicitly
  request signing.
- Choose one explicit `VERSION` and reuse it across build, push, and promotion
  commands. Otherwise each Make invocation generates a new UTC timestamp.
- Builds export committed submodule `HEAD` contents using `git archive`.
  Uncommitted upstream edits are not included. Do not edit generated
  [build/sources/](../../build/sources/) content.
- Publishing and promotion update registry tags immediately. They do not run
  tests, request approval, deploy services, or provide an atomic multi-image
  transaction. A failure can leave only some images published or promoted.

## Common Workflows

### Build The Revisions Recorded In Releng

```sh
VERSION=20261104T150000
make build_prep
make VERSION="$VERSION" dockers
```

`dockers` already depends on `build_prep` through `build`, so the explicit
preparation command is optional. It is useful for inspecting the selected
submodule commits before building.

### Update To An Upstream Branch And Build

```sh
make update_what_to_build
make VERSION=20261104T150000 dockers
```

The default branch is `origin/main`. To select another branch:

```sh
make BRANCH=origin/feature-branch update_what_to_build
make VERSION=20261104T150000 dockers
```

The selected branch must exist in every submodule. This is not a per-service
branch selector. Review the resulting releng commits before continuing.

### Build One Or Several Runtime Images

```sh
make VERSION=20261104T150000 webapp
make VERSION=20261104T150000 worker fastapi
make VERSION=20261104T150000 vccs
```

These are not runtime-only shortcuts: each target also builds the shared
artifacts through `build`. All except `vccs` additionally build `runtime_common`.
Requesting several targets in one invocation shares their common prerequisites.

To restrict the images built by `dockers`:

```sh
make VERSION=20261104T150000 DOCKERS="webapp worker" dockers
```

`DOCKERS` does **not** restrict publication or promotion; those targets explicitly
list all seven images.

### Build, Publish, And Promote A Release

```sh
VERSION=20261104T150000
make VERSION="$VERSION" dockers
make VERSION="$VERSION" dockers_tagpush
# Perform the required testing checks before staging.
make VERSION="$VERSION" staging_release
# Perform the required staging checks before production.
make VERSION="$VERSION" production_release
```

The last three commands do not build images or update submodules:

1. `dockers_tagpush` tags and pushes existing local versioned runtime images.
2. `staging_release` pulls testing images, retags them, and pushes staging tags.
3. `production_release` pulls staging images, retags them, and pushes production
   tags.

Promotion can run on a different host if the source tags exist in the registry.
It does not require the original local build images.

### Use Another Registry Or Promotion Lane

```sh
make VERSION=20261104T150000 REGISTRY=registry.example.org dockers_tagpush
make VERSION=20261104T150000 REGISTRY=registry.example.org staging_release
make VERSION=20261104T150000 REGISTRY=registry.example.org production_release
```

Custom source and destination suffixes:

```sh
make VERSION=20261104T150000 TAGSUFFIX=candidate dockers_tagpush
make VERSION=20261104T150000 TAGSUFFIX=candidate STAGINGTAG=acceptance staging_release
make VERSION=20261104T150000 STAGINGTAG=acceptance PRODTAG=live production_release
```

Reuse matching registry and suffix settings in subsequent commands.

### Rebuild Shared Layers Or Refresh APT

```sh
make VERSION=20261104T150000 prebuild
make VERSION=20261104T150000 runtime_common
make VERSION=20261104T150000 build
make VERSION=20261104T150000 APT_REFRESH=20261105T090000 dockers
```

`APT_REFRESH` defaults to `VERSION`. Changing it invalidates the APT layer cache
in `prebuild`, `runtime_common`, and `vccs`; it is not a global Docker
`--no-cache` switch. `prebuild` and `runtime_common` build with `--pull`, while
`vccs` explicitly pulls its Luna base.

### Preview Commands Without Building Or Publishing

```sh
make -n VERSION=20261104T150000 dockers
make -n VERSION=20261104T150000 dockers_tagpush
make -n VERSION=20261104T150000 staging_release
```

The top-level recipes use literal `make` commands, so these dry runs print the
delegated invocations rather than expanding their recipes. To inspect one
delegated publication or promotion:

```sh
make -n -C images/webapp VERSION=20261104T150000 TAGSUFFIX=testing docker_tagpush
make -n -C images/webapp VERSION=20261104T150000 SRCTAG=testing DSTTAG=staging tag_copypush
```

## Complete Target Reference

### Help And Source Selection

| Target | Prerequisites | Behavior |
| --- | --- | --- |
| `all` | None | Default target; prints help showing the selected branch and runtime image list. |
| `build_prep` | None | Runs `git submodule update --init`, then `git submodule update`, then displays each submodule's current commit summary. Restores recorded submodule revisions rather than fetching the latest branch tips. |
| `update_what_to_build` | `build_prep` | Runs `git pull` in releng; checks out `MAINBRANCH` in every submodule, fetches `origin`, then checks out `BRANCH`; displays summaries and attempts one releng gitlink commit per entry in `SUBMODULES`. |
| `init_submodules` | None | Creates the repos directory and runs `git submodule add https://github.com/SUNET/<name>.git` for each entry in `SUBMODULES`. Intended for registration, not ordinary checkout initialization; existing registrations can cause errors. Use `build_prep` for normal setup. |
| `deinit_submodules` | None | Runs forced `git submodule deinit -f` for each entry in `SUBMODULES` from the repos directory. Can remove submodule working trees containing local changes. Preserve any work first. |

`update_what_to_build` always checks out `MAINBRANCH` before fetching, even when
`BRANCH` is overridden. Its per-submodule `git commit` commands end in `|| true`:
a successful Make exit does not prove that all pointer commits were created or
signed. Check `git status` and `git log --show-signature` afterward. This target
does not push commits; pushes are performed manually.

### Shared Build Stages

| Target | Prerequisites | Result |
| --- | --- | --- |
| `prebuild` | None | Builds the toolchain/dependency image `eduid-prebuild:latest`. Passes `VERSION` and `APT_REFRESH` to its delegated Makefile. |
| `runtime_common` | None | Builds the shared Debian runtime parent as `eduid-runtime-common:<VERSION>` and tags it `eduid-runtime-common:latest`. |
| `build` | `build_prep`, `prebuild` | Writes `build/submodules.txt`; exports clean submodule snapshots and revision files; builds `eduid-build:<VERSION>` containing shared Python environments and frontend artifacts. |
| `dockers` | `build`, all targets in `DOCKERS` | Builds the selected runtime images; defaults to all seven. Does not publish them. |

The export step replaces the generated source directory. The shared build
creates artifacts for all configured services/frontends even when only one
runtime target is requested.

### Individual Runtime Builds

Every runtime target creates `eduid-<target>:<VERSION>` and also updates its local
`eduid-<target>:latest` tag.

| Target | Prerequisites | Delegated Makefile |
| --- | --- | --- |
| `webapp` | `build`, `runtime_common` | [images/webapp/Makefile](../../images/webapp/Makefile) |
| `worker` | `build`, `runtime_common` | [images/worker/Makefile](../../images/worker/Makefile) |
| `satosa_scim` | `build`, `runtime_common` | [images/satosa_scim/Makefile](../../images/satosa_scim/Makefile) |
| `fastapi` | `build`, `runtime_common` | [images/fastapi/Makefile](../../images/fastapi/Makefile) |
| `admintools` | `build`, `runtime_common` | [images/admintools/Makefile](../../images/admintools/Makefile) |
| `html` | `build`, `runtime_common` | [images/html/Makefile](../../images/html/Makefile) |
| `vccs` | `build` | [images/vccs/Makefile](../../images/vccs/Makefile) |

VCCS uses its separately configured Luna base, not `runtime_common`.

### Publication And Promotion

All three targets process `webapp`, `worker`, `satosa_scim`, `fastapi`,
`admintools`, `html`, and `vccs` in that order. They have no build prerequisites.

| Target | Input | Registry output |
| --- | --- | --- |
| `dockers_tagpush` | Local `eduid-<image>:<VERSION>` | `<REGISTRY>/eduid/<image>:<VERSION>-<TAGSUFFIX>` |
| `staging_release` | `<REGISTRY>/eduid/<image>:<VERSION>-<TAGSUFFIX>` | `<REGISTRY>/eduid/<image>:<VERSION>-<STAGINGTAG>` |
| `production_release` | `<REGISTRY>/eduid/<image>:<VERSION>-<STAGINGTAG>` | `<REGISTRY>/eduid/<image>:<VERSION>-<PRODTAG>` |

**Exception: `admintools` omits `VERSION` from registry tags.** Its tags are
`<REGISTRY>/eduid/admintools:testing`, `:staging`, and `:production` with the
default suffixes. Publication still requires the local
`eduid-admintools:<VERSION>` image. Promotion uses whichever image currently has
the source suffix, not necessarily the requested version; publishing a newer
testing image overwrites that lane's previous `admintools` reference.

To publish or promote only one image, use its delegated target explicitly:

```sh
make -C images/webapp VERSION=20261104T150000 TAGSUFFIX=testing docker_tagpush
make -C images/webapp VERSION=20261104T150000 SRCTAG=testing DSTTAG=staging tag_copypush
make -C images/webapp VERSION=20261104T150000 SRCTAG=staging DSTTAG=production tag_copypush
```

### Cleanup And Submodule Maintenance

| Target | Prerequisites | Behavior |
| --- | --- | --- |
| `clean` | None | Runs `docker rmi eduid-prebuild -f`. Does not remove other images, Docker build cache, source exports, or submodules. Can fail if the image is absent. |
| `real_clean` | `clean`, `init_submodules` | Removes the prebuild image and attempts to add submodules. Despite its name, this is not a full cleanup and does not deinitialize submodules. |

```sh
make clean
```

Do not use `real_clean` as a general reset command. `deinit_submodules` and
`init_submodules` are maintenance operations, not required release steps.

## Variables

Command-line assignments such as `make VERSION=... target` propagate to delegated
Make invocations. Defaults below describe the current implementation.

| Variable | Default | Use |
| --- | --- | --- |
| `VERSION` | UTC timestamp, `YYYYMMDDTHHMMSS` | Local build tag and versioned registry tag prefix. Reuse explicitly across separate invocations. |
| `APT_REFRESH` | `VERSION` | APT cache-refresh build argument for prebuild, runtime-common, and VCCS images. |
| `REGISTRY` | `platform.sunet.se` in service Makefiles | Registry host, optionally including a port; image paths append `/eduid/<image>`. |
| `TAGSUFFIX` | `testing` | Publication suffix and staging source suffix. |
| `STAGINGTAG` | `staging` | Staging destination suffix and production source suffix. |
| `PRODTAG` | `production` | Production destination suffix. |
| `MAINBRANCH` | `origin/main` | Initial submodule checkout during source updates; default for `BRANCH`. |
| `BRANCH` | `MAINBRANCH` | Final branch/revision checked out in every submodule by `update_what_to_build`. |
| `DOCKERS` | `webapp worker satosa_scim fastapi admintools html vccs` | Runtime targets included by `dockers`; does not filter push/promotion. |
| `RUNTIME_COMMON_DOCKERS` | `webapp worker satosa_scim fastapi admintools html` | Internal list assigning `build` and `runtime_common` prerequisites; normally leave unchanged. |
| `SUBMODULES` | `eduid-backend eduid-html eduid-front eduid-managed-accounts` | Names used by registration, deinitialization, and pointer-commit loops. Does not filter `git submodule foreach`, `build_prep`, or the fixed source-export list. |
| `REPOS` | `$(CURDIR)/build/repos` | Directory used by registration/deinitialization. Does not relocate `.gitmodules` or the separate build Makefile's exports. |
| `DATETIME` | UTC timestamp computed when Make starts | Internal default value for `VERSION`. |
| `DEBIAN_VERSION` | Defined in [base-images.mk](../../versions/base-images.mk) | Debian codename used by shared base-image builds. |
| `VCCS_LUNA_IMAGE_REPO` | Defined in [runtime-images.mk](../../versions/runtime-images.mk) | Repository pulled for the VCCS Luna base. |
| `VCCS_LUNA_IMAGE_TAG` | Defined in [runtime-images.mk](../../versions/runtime-images.mk) | Luna base tag used by VCCS. |
| `NODE_MAJOR` | Defined in [build-toolchain.mk](../../versions/build-toolchain.mk) | Node.js major used by the prebuild image for frontend builds. |
| `NODE_IMAGE` | `docker.io/library/node:$(NODE_MAJOR)-$(DEBIAN_VERSION)-slim` in the prebuild Makefile | Official Node image from which prebuild copies Node.js and bundled npm. A command-line override replaces the composed tag. |
| `DOCKERIMAGE` | `$(REGISTRY)/eduid/<image>` in each service Makefile | Full registry image name for single-service operations. Do not override globally for multi-image publication: every service would use the same destination. |

Some variables use ordinary or immediate Make assignments rather than `?=`.
Prefer command-line overrides instead of assuming environment variables will
override repository settings. For durable image-input changes, review the
version files rather than relying on one-off overrides.

## Operational Checks

- Before building: inspect `git status` and `git submodule status`; confirm
  committed upstream revisions and the chosen `VERSION`.
- After building: check that all requested `eduid-<image>:<VERSION>` images exist
  locally before running the all-image push target.
- Before promotion: verify source registry tags and required environment checks.
  Treat the unversioned `admintools` lane separately.
- After a partial failure: inspect which tags were updated before rerunning.
  There is no automatic rollback.
- Prefer serial execution unless you have separately validated parallel
  execution; the Makefile does not sequence every shared prerequisite against
  the others.

See also [build operations](../operations/build.md),
[promotion](../operations/promotion.md), and [rollback](../operations/rollback.md).
