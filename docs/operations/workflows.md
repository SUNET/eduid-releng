# Command Workflows: Local, CI, And Releases

## Scope

Use this guide to choose commands by task and execution environment. Run them
from the releng repository root unless a command explicitly uses `make -C`.
For every target and variable, see the
[Makefile operator manual](../reference/makefile-operator-manual.md).

Commands reflect the [top-level Makefile](../../Makefile), delegated Makefiles
under [images/](../../images/), [build/Makefile](../../build/Makefile), and the
[Forgejo workflow](../../.forgejo/workflows/build-action.yaml).

## Before You Start

- Have Git, GNU Make, a working Docker daemon, and network access.
- Authenticate to registries when required for base-image pulls or publishing.
- Commit upstream changes in their owning repositories. Releng exports committed
  submodule revisions, not uncommitted edits or manually modified source exports.
- Use one explicit version across separate build, push, and promotion commands.
- Build and promotion commands do not run application tests or deploy services.
  Complete the relevant checks before advancing a release.

The examples use a fixed sample version. Replace it with your chosen version.
Shell variables set in an example apply only to that shell session.

## 1. Local Environments

### Inspect Available Commands And Source Revisions

```sh
make
git status --short
git submodule status
```

`make` without a target only prints help. Inspect local changes before running
commands that update submodules.

### Prepare A Checkout Using Recorded Revisions

```sh
make build_prep
git submodule status
```

This initializes submodules and checks out the revisions recorded by releng.
It does not select the newest upstream commits. Normal builds already include
this preparation step.

### Select New Upstream Revisions

Default upstream branch:

```sh
make update_what_to_build
```

A branch available in every submodule:

```sh
make BRANCH=origin/feature-branch update_what_to_build
```

This pulls the releng repository, checks out and fetches submodule branches,
and attempts to commit each updated submodule pointer in releng. Configure
signed Git commits beforehand. Commit errors are ignored by this recipe, so
verify the resulting pointers and signed commits explicitly:

```sh
git status --short
git submodule status
git log --show-signature -n 4
```

Review the changes before building. This is a maintainer source-selection
operation, not a routine CI build step; pushes remain manual.

### Build Without Publishing

Build all runtime images:

```sh
make VERSION=20261104T150000 dockers
```

Build one image or a subset:

```sh
make VERSION=20261104T150000 webapp
make VERSION=20261104T150000 worker fastapi
make VERSION=20261104T150000 DOCKERS="webapp worker" dockers
```

Each runtime target includes the shared artifact build. Non-VCCS images also
build the common runtime parent; VCCS uses its separate Luna base.
These commands create local `eduid-<image>:<VERSION>` and `:latest` tags.
They do not start a development stack or configure application services.

Inspect a resulting image:

```sh
docker image inspect eduid-webapp:20261104T150000
```

### Build Shared Stages Or Refresh OS Packages

```sh
make VERSION=20261104T150000 prebuild
make VERSION=20261104T150000 runtime_common
make VERSION=20261104T150000 build
make VERSION=20261104T150000 APT_REFRESH=20261105T090000 dockers
```

These are alternative tasks, not a required sequence before `dockers`.
Changing `APT_REFRESH` refreshes the APT cache key for prebuild, runtime-common,
and VCCS layers; it does not disable all Docker caching.

### Preview Or Clean Up

```sh
make -n VERSION=20261104T150000 dockers
make clean
```

The dry run prints top-level commands, including delegated Make invocations,
but does not expand their recipes. `clean` forcibly removes only the prebuild
image; it is not a full cache, runtime-image, or source cleanup.
Do not use `real_clean` as a reset: it also attempts to register submodules.
See the manual for the potentially destructive submodule-maintenance targets.

## 2. CI Environments

### What The Current Forgejo Job Does

The configured workflow runs on branch pushes, including feature branches, and
ignores tag pushes. It checks out releng, logs in to `platform.sunet.se`, lists
Docker builders, and runs:

```sh
DOCKER_BUILDKIT=0 make dockers dockers_tagpush REGISTRY=platform.sunet.se
```

Both targets run in one serial Make invocation, sharing the generated timestamp
version. The build initializes the recorded submodule revisions; CI does not
run `update_what_to_build` or automatically select the latest upstream branch.

The job builds and publishes testing images. It has no application-test,
staging-promotion, production-promotion, or deployment steps.
Every branch build can update the shared, unversioned `admintools:testing` tag.

### Reproduce The CI Build With An Explicit Version

On an authenticated build host:

```sh
VERSION=20261104T150000
DOCKER_BUILDKIT=0 make VERSION="$VERSION" REGISTRY=platform.sunet.se dockers dockers_tagpush
```

This publishes to the real registry. To reproduce only the build:

```sh
DOCKER_BUILDKIT=0 make VERSION=20261104T150000 dockers
```

Use CI-managed credentials; do not place passwords or tokens in commands,
documentation, or source control. The runner needs Docker access, registry
permissions, and access to the configured VCCS Luna base image.

### Use Separate Build And Publish Steps

For automation that splits these operations, provide the same version to both
steps:

```sh
make VERSION=20261104T150000 dockers
make VERSION=20261104T150000 REGISTRY=platform.sunet.se dockers_tagpush
```

The publish step requires the versioned images in its local Docker daemon.
Separate runners need an explicit image-transfer mechanism; a source checkout
alone is insufficient. Neither the Makefile nor the current workflow implements
that transfer.

Preserve the chosen version, releng revision, submodule revisions, and build logs
as release evidence. Avoid simultaneous build/push targets with `make -j`:
publication has no dependency ensuring the build finishes first.

## 3. Release Steps

### Step 1: Choose Inputs And A Version

Review the releng commit and its recorded submodule revisions. Run
`update_what_to_build` only if deliberately changing release inputs.

```sh
git status --short
git submodule status
VERSION=20261104T150000
REGISTRY=platform.sunet.se
```

The remaining commands assume this shell retains `VERSION` and `REGISTRY`.
If CI has already published the intended version, skip the local build/publish
step and use that exact version for promotion.

### Step 2: Build And Publish Testing Images

```sh
make VERSION="$VERSION" dockers
make VERSION="$VERSION" REGISTRY="$REGISTRY" dockers_tagpush
```

`dockers_tagpush` does not build missing images. It publishes all seven runtime
images even if `DOCKERS` was restricted during the build.

For most images the testing tag is
`<REGISTRY>/eduid/<image>:<VERSION>-testing`.
For `admintools`, it is `<REGISTRY>/eduid/admintools:testing`, with no version.

### Step 3: Validate Testing And Promote To Staging

Confirm all expected testing images exist and complete testing checks before:

```sh
make VERSION="$VERSION" REGISTRY="$REGISTRY" staging_release
```

This pulls testing tags, retags them as staging, and pushes them. It does not
rebuild, deploy, or validate the services.

### Step 4: Validate Staging And Promote To Production

After staging validation:

```sh
make VERSION="$VERSION" REGISTRY="$REGISTRY" production_release
```

This pulls staging tags and pushes production tags without rebuilding.
Most images use `<VERSION>-staging` and `<VERSION>-production`;
`admintools` uses only `staging` and `production`.

**Check the `admintools` source lane separately before each promotion.**
The supplied version does not identify that image in the registry. A newer
build or promotion may already have replaced the unversioned source tag.

### Optional: Custom Promotion Lanes

```sh
make VERSION="$VERSION" REGISTRY="$REGISTRY" TAGSUFFIX=candidate dockers_tagpush
make VERSION="$VERSION" REGISTRY="$REGISTRY" TAGSUFFIX=candidate STAGINGTAG=acceptance staging_release
make VERSION="$VERSION" REGISTRY="$REGISTRY" STAGINGTAG=acceptance PRODTAG=live production_release
```

Suffixes must match between each destination and the next step's source.
Changing suffixes still publishes or promotes every runtime image.

### Optional: Publish Or Promote Only One Service

Use a delegated service target rather than filtering `DOCKERS`:

```sh
make -C images/webapp VERSION="$VERSION" REGISTRY="$REGISTRY" TAGSUFFIX=testing docker_tagpush
make -C images/webapp VERSION="$VERSION" REGISTRY="$REGISTRY" SRCTAG=testing DSTTAG=staging tag_copypush
make -C images/webapp VERSION="$VERSION" REGISTRY="$REGISTRY" SRCTAG=staging DSTTAG=production tag_copypush
```

This intentionally advances only that service, not a complete release set.

### If Publication Or Promotion Fails

Commands update images sequentially, with no atomic transaction or automatic
rollback. Inspect which registry tags changed before retrying. Do not assume a
failed command left the previous release intact.

Promotion can run from a different authenticated host because it pulls source
tags from the registry. Before a rollback, verify the intended source images
still exist; an old `VERSION` alone cannot recover an overwritten `admintools`
tag. See [rollback operations](rollback.md).
