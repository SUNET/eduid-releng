# Base Image Versioning Policy

## Purpose

Define the project's operating-system and Python interpreter policy, and document
where releng-owned image input review points live.

The original project baseline is recorded in
[ADR 0000](../adr/0000-use-debian-stable-and-debian-provided-python.md).
This policy describes its operational application and review points.

## Source Of Truth

- `versions/base-images.mk`
- `versions/runtime-images.mk`
- `versions/build-toolchain.mk`
- `images/prebuild/Dockerfile`
- `images/prebuild/Makefile`
- `build/setup-venv.sh`

## Debian Stable Baseline

Debian stable is the project baseline for build and runtime images. Any exception,
including an externally supplied service base, must be explicitly reviewed and
documented.

Track Debian stable through a reviewed release codename in `DEBIAN_VERSION`,
rather than relying on the floating `stable` tag to advance images automatically.
The shared base uses the mutable codename tag without a digest pin.
When a new Debian stable release becomes available, review the baseline update
and validate affected builds and services before adopting it.

## Python Interpreter Policy

Releng trusts Python supplied and maintained by Debian packages for the selected
stable release. Debian determines the Python version; releng does not independently
pin its minor version or replace package-managed Python files with an interpreter
copied from another image.

Use `uv` to manage virtual environments and Python dependencies, not to provide
interpreters. Set `UV_PYTHON_DOWNLOADS=never` and select the Debian interpreter,
avoiding any unrelated interpreter or virtual environment inherited through
`PATH` from an external base image.

This policy governs releng-managed Python environments; it does not redefine the
interpreter used by software bundled in externally supplied base images.
Accepting Debian's Python version does not override upstream application Python
requirements. Baseline updates must validate those requirements, environment
creation, dependency installation, and runtime behavior. Keep required runtime
Python packages installed when removing build-only dependencies.

See [ADR 0007](../adr/0007-use-uv-for-releng-python-environment-management.md)
for the environment-management decision.

## Releng-Owned Toolchain Selection

Upstream projects declare the interpreter and build-tool compatibility they
require; releng selects the environment used to build and run a release.
Compatibility requirements constrain that selection but do not automatically
choose or replace the production toolchain.

For `eduid-backend`, production uses Debian-packaged Python from the selected
Debian stable release. Releng reviews and commits `DEBIAN_VERSION` and accepts
the Python version supplied by that release, rather than selecting an
interpreter from the backend repository. The policy is to follow Debian stable
through reviewed codename updates, not to switch automatically whenever a new
release becomes stable. Backend compatibility must be validated before adopting
the new baseline.

The same ownership principle applies to Node.js: releng selects and commits
`NODE_MAJOR` in `versions/build-toolchain.mk`. The frontend's `.nvmrc` may
select Node for upstream development and CI, but it does not control releng's
release builds. Neither `.nvmrc` nor package engine ranges are read to derive
the releng major. A frontend revision change must not implicitly change the
shared production build toolchain.

This is an analogy of responsibility, not interpreter provenance. Python is
an application runtime maintained by Debian; Node.js is a frontend build tool
copied, with bundled npm, from an official Node image. Releng does not require
the Debian-packaged Node version or independently pin npm. The generated
frontend artifacts are packaged for deployment; Node is not their browser
runtime.

Keeping Node selection in releng provides a separate, reviewable commit for
major upgrades and allows compatibility validation of both `eduid-front` and
`eduid-managed-accounts`, which share the toolchain. Upstream maintainers own
their compatibility declarations, lockfiles, and build fixes; releng maintainers
own toolchain selection, release-input review, and validation. A mismatch must
be resolved before release, not treated as permission to ignore upstream
requirements. The frontend CI and releng can intentionally have separate
version settings, so passing upstream CI alone does not establish release-build
compatibility.

This policy selects a Node major, not an exact Node/npm version. Minor and
patch updates follow the mutable `node:<major>-<debian>-slim` tag when prebuild
is rebuilt with `--pull`; Debian image and APT inputs also remain mutable.
No digest pinning is used. Consequently, reviewed configuration commits make
major and baseline changes explicit, but do not guarantee identical historical
rebuilds or eliminate regressions within a major. Validate fresh toolchains
against both frontend builds and retain actual Node/npm versions in release
evidence. See [Frontend Toolchain Updates](../operations/build.md#frontend-toolchain-updates)
for operational checks.

## Shared Debian Base

The Debian-based build and runtime images use `DEBIAN_VERSION` from
`versions/base-images.mk` as `debian:${DEBIAN_VERSION}`.

The codename is the releng-owned review point; the image behind that tag can
change without a repository change. Both `prebuild` and `runtime_common` build
with `--pull` to fetch the current base. The prebuild target always invokes
Docker, even when its image already exists; eligible layers can be cached.

## Release-Scoped APT Cache

`APT_REFRESH` defaults to `VERSION` and is passed to the prebuild, runtime-common,
and VCCS builds. Each Dockerfile declares it immediately before its APT layer,
so a new value invalidates that layer and subsequent layers. Root Make targets
pass the same value to all three builds. Direct child Make invocations must also
provide a nonempty `VERSION` or `APT_REFRESH`; runtime-common and VCCS still
require `VERSION` for their image tags.

A new release identifier reruns APT updates and upgrades. Rebuilding the same
release can reuse those layers if the base and other inputs have not changed.
To refresh packages again while keeping the release identifier, use a new token:

```bash
make VERSION=my-release APT_REFRESH="$(date -u +%Y%m%dT%H%M%S)" dockers
```

The default root `VERSION` is a UTC timestamp. To reuse cache across invocations,
provide a stable release identifier explicitly. Mutable base tags and live APT
repositories still prevent this from being a reproducibility guarantee.

The three base APT layers use `APT::Update::Error-Mode=any` so a failed index
download fails the build rather than silently accepting partial repository data.
Validate argument propagation with Make dry runs for the three child builds,
using both a default release token and an explicit refresh override.

## VCCS Runtime Base

`vccs` uses `VCCS_LUNA_IMAGE_REPO` and `VCCS_LUNA_IMAGE_TAG` from
`versions/runtime-images.mk`. This selects the Luna client base from
`platform.sunet.se/keyforge/luna-base`, separately from the shared Debian base.

That selection is currently tag-based, not digest-based.

The VCCS build explicitly pulls the selected Luna base before building with
release-scoped APT cache invalidation. It does not use `--pull` on the multi-stage
build because `eduid-build:$VERSION` is a local release artifact, not an external
base to refresh.

These builds target Debian package fixes available from their configured APT
repositories when the APT layers execute. Reusing a refresh token can reuse an
earlier package state. Updates to proprietary Luna components require separate
review of the upstream base. Promotion does not rebuild images; patches published
after a build require a new tested release.

VCCS copies the shared FastAPI venv from `eduid-build:$VERSION` and uses
Debian-packaged runtime Python in the Luna-based image.
The selected base must remain compatible with the venv's Python version and
native dependencies.

For a base substitution, validate the Make dry run, build the VCCS image, and
check that its copied Python venv runs, native and Luna library dependencies
resolve, and client certificate generation succeeds. HSM connectivity requires a separate
check with deployment certificates and a configured HSM.

## Version Review

The configured Debian codename is defined by `DEBIAN_VERSION` in
`versions/base-images.mk`.

Review and validate major-release changes before manually updating
`DEBIAN_VERSION` in `versions/base-images.mk`. There is no automatic Debian
codename check or update helper.