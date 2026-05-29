# Debian Package Snapshotting Plan

## Purpose

This note describes a repo-specific plan to pin Debian package inputs via snapshotting so repeated releng builds stop depending on live Debian mirrors.

The repository now pins Debian base images by tag plus digest, but the Debian package layer is still mutable because the Dockerfiles run `apt-get update`, `apt-get dist-upgrade`, and package installs against whatever the active mirrors serve at build time.

## Current Problem

The mutable apt input currently affects these releng-owned Dockerfiles:

- `images/prebuild/Dockerfile`
- `images/webapp/Dockerfile`
- `images/worker/Dockerfile`
- `images/fastapi/Dockerfile`
- `images/satosa_scim/Dockerfile`
- `images/admintools/Dockerfile`
- `images/html/Dockerfile`
- `images/vccs/Dockerfile`

This matters because:

- the same source revisions can still produce different package sets over time
- the shared build image and runtime images can drift apart even when they share the same Debian base tag and digest
- copied virtual environments can fail later if build-time and runtime Debian packages diverge enough
- release review still does not approve the exact OS package set that gets installed

## Recommended Target State

The repo should converge on this state:

1. Every releng-owned Debian package install resolves from reviewed Debian snapshot timestamps rather than live mirrors.
2. Shared Debian package snapshot inputs are centralized alongside the existing base-image pins.
3. Debian-based Dockerfiles stop using `apt-get dist-upgrade` during image builds.
4. Security or bugfix movement in the Debian layer happens by intentionally reviewing and updating the base-image digest and snapshot timestamp, not by rebuild-time mirror drift.
5. CI can verify that the same reviewed snapshot inputs produce the same package manifest across repeated builds.

## Recommended Snapshot Strategy

Use `snapshot.debian.org` as the immutable Debian package source of truth.

Recommended initial shape:

- keep the current `DEBIAN_VERSION` and `DEBIAN_DIGEST` pins in `versions/base-images.mk`
- add one reviewed snapshot timestamp for shared Debian package inputs
- only split into separate archive timestamps if one shared timestamp proves operationally unreliable

Recommended first-pass variables:

```makefile
DEBIAN_VERSION := trixie
DEBIAN_DIGEST := sha256:...
DEBIAN_SNAPSHOT_TIMESTAMP := 20260529T000000Z
```

If one shared timestamp is not sufficient for both the main archive and the security archive, expand to this instead:

```makefile
DEBIAN_ARCHIVE_SNAPSHOT_TIMESTAMP := 20260529T000000Z
DEBIAN_SECURITY_SNAPSHOT_TIMESTAMP := 20260529T000000Z
```

The default recommendation is to start with one timestamp because it keeps the review surface smaller and matches the current shared-Debian-input model in the repo.

## Why One Timestamp First

One reviewed timestamp has practical advantages:

- it gives the repo one clear Debian package freeze point per review cycle
- it keeps the build and runtime images aligned by default
- it matches the existing pattern where shared Debian inputs are centralized rather than per-service

The fallback to two timestamps should remain available because:

- `debian` and `debian-security` are separate archives
- snapshot availability or operational timing could make one shared timestamp inconvenient in practice
- forcing one timestamp at all costs is worse than reintroducing mutable package inputs

## Recommended Apt Source Configuration

The Dockerfiles should stop using the default live Debian sources shipped in the base image and instead write explicit snapshot-backed sources before `apt-get update`.

The intended source set for a Debian-based image on `trixie` is:

- `http://snapshot.debian.org/archive/debian/<timestamp>/ trixie main`
- `http://snapshot.debian.org/archive/debian/<timestamp>/ trixie-updates main`
- `http://snapshot.debian.org/archive/debian-security/<timestamp>/ trixie-security main`

The build should also set apt snapshot behavior explicitly:

- disable `Valid-Until` enforcement for snapshot repos
- enable a small retry count for snapshot fetches
- remove the default `/etc/apt/sources.list` or equivalent live-mirror configuration so there is no accidental fallback

Illustrative Dockerfile pattern:

```dockerfile
ARG DEBIAN_VERSION
ARG DEBIAN_SNAPSHOT_TIMESTAMP

RUN printf '%s\n' \
      'Acquire::Check-Valid-Until "false";' \
      'Acquire::Retries "3";' \
      > /etc/apt/apt.conf.d/99releng-snapshot \
    && rm -f /etc/apt/sources.list \
    && printf '%s\n' \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT_TIMESTAMP}/ ${DEBIAN_VERSION} main" \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT_TIMESTAMP}/ ${DEBIAN_VERSION}-updates main" \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT_TIMESTAMP}/ ${DEBIAN_VERSION}-security main" \
      > /etc/apt/sources.list.d/releng-snapshot.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends ...
```

`http` is acceptable here because Debian apt integrity comes from signed Release metadata and package signatures, not from transport confidentiality. That avoids introducing a bootstrap dependency on extra TLS setup in minimal base images.

## Critical Design Decision: Remove `dist-upgrade`

Snapshotting only partly helps if the repo keeps `apt-get dist-upgrade` in the Dockerfiles.

The better contract is:

- base image digest controls the reviewed starting filesystem
- snapshot timestamp controls the reviewed apt repository state
- package install lists control which extra packages are added

Under that model, the Dockerfiles should use explicit package installation rather than `dist-upgrade`.

That is important because `dist-upgrade` still broadens the package change surface beyond what the Dockerfile actually declares.

## Repo-Specific Constraint: Build Context Layout

The service Docker builds currently run from each service directory with `docker build .`.

That means a single shared apt-configuration script is not trivial to reuse immediately, because each service build context is local to its own directory.

That creates two realistic implementation choices:

1. First pass: duplicate a short snapshot configuration snippet in each affected Dockerfile.
2. Later cleanup: change the build contexts or Docker invocation style so a shared helper file can be copied from the repo root.

The recommended path is to accept a small amount of short-term duplication for the first rollout rather than coupling snapshotting to a broader build-system refactor.

## Proposed Implementation Plan

### Phase 1: Centralize reviewed snapshot inputs

Add Debian package snapshot variables to `versions/base-images.mk`.

Recommended first pass:

- `DEBIAN_SNAPSHOT_TIMESTAMP := ...`

Potential later expansion if needed:

- `DEBIAN_ARCHIVE_SNAPSHOT_TIMESTAMP := ...`
- `DEBIAN_SECURITY_SNAPSHOT_TIMESTAMP := ...`

Also extend the top-level reporting targets so `make show-base-image-versions` prints the snapshot pin alongside the base tag and digest.

### Phase 2: Add validation and update tooling

Do not make the updater blindly chase the newest available snapshot timestamp by default.

That would reintroduce unwanted drift disguised as automation.

Instead, add tooling with these responsibilities:

- validate that the configured snapshot timestamp resolves for all required suites
- print the currently reviewed timestamp and its reachable snapshot URLs
- optionally help set a candidate new timestamp after a human has decided to advance the Debian package state

Reasonable tooling options:

- extend `scripts/update-base-image-versions.sh` to validate snapshot inputs and only update them when explicitly asked for a reviewed timestamp
- or add a new `scripts/check-debian-snapshot.sh` helper if keeping snapshot logic separate from base-image digest logic is clearer

The important policy point is that snapshot timestamps should be reviewed inputs, not automatically floating ones.

### Phase 3: Roll out snapshot-backed apt sources in the build path first

Start with `images/prebuild/Dockerfile`.

Why first:

- it installs the compiler and header packages used for Python builds
- it is the shared Debian package foundation for the exported Python environments
- if snapshotting is wrong here, the failure is immediate and easy to detect during `build/setup-venv.sh`

Changes in this phase:

- add the snapshot timestamp build arg
- replace live apt sources with snapshot-backed sources
- remove `dist-upgrade`
- keep package installation explicit and preferably `--no-install-recommends`

### Phase 4: Roll out snapshot-backed runtime images

After `prebuild` is stable, apply the same pattern to:

- `images/webapp/Dockerfile`
- `images/worker/Dockerfile`
- `images/fastapi/Dockerfile`
- `images/satosa_scim/Dockerfile`
- `images/admintools/Dockerfile`
- `images/html/Dockerfile`

This keeps the shared build image and the copied-venv runtime images aligned on the same reviewed Debian package state.

### Phase 5: Handle `vccs` as an explicit follow-up decision

`images/vccs/Dockerfile` is structurally different because it starts from the separately pinned Luna runtime image rather than from the shared Debian base flow.

The plan should explicitly verify whether the Luna base remains Debian-compatible with the shared `DEBIAN_VERSION` policy.

If yes:

- reuse the same snapshot timestamp policy in `vccs`

If no:

- introduce a `VCCS_*`-namespaced snapshot pin rather than forcing an incorrect shared Debian contract

The important point is to keep `vccs` explicit rather than silently assuming it matches the shared Debian image family.

### Phase 6: Add focused reproducibility checks

Once the Dockerfiles use snapshot-backed apt inputs, add narrow validation that can falsify regressions quickly.

Recommended checks:

- build `prebuild` twice from the same git revision and compare installed package manifests with `dpkg-query -W`
- build one shared-venv runtime image twice and compare package manifests or image digests after filtering obvious timestamp noise
- confirm `apt-cache policy` shows only `snapshot.debian.org` sources for the releng-installed packages
- fail CI if releng-owned Dockerfiles still contain `apt-get dist-upgrade`
- fail CI if releng-owned Dockerfiles install packages from live Debian mirrors rather than snapshot URLs

## Rollout Order

The safest rollout order is:

1. Add reviewed snapshot pins and validation tooling.
2. Convert `images/prebuild/Dockerfile`.
3. Validate Python environment builds.
4. Convert the Debian-based runtime Dockerfiles that copy shared virtual environments.
5. Convert `images/html/Dockerfile` and `images/admintools/Dockerfile`.
6. Review `vccs` separately.
7. Add CI checks that prevent regression to floating apt inputs.

## Operational Update Policy

The Debian package layer should move only by review, not by rebuild timing.

Recommended policy:

- update the Debian base digest and snapshot timestamp together when intentionally refreshing the Debian platform state
- treat emergency Debian security movement as a reviewed releng change that updates those pins plus the relevant validation evidence
- keep the old snapshot timestamp in git history as the rollback point

This gives the repo a clean answer to the question: which Debian package state was approved for this release?

## Risks and Mitigations

### 1. Snapshot service performance or availability

Risk:

- `snapshot.debian.org` can be slower than live mirrors

Mitigation:

- add apt retries
- keep validation explicit
- if needed later, front the same reviewed snapshot URLs with an internal cache or mirror without reintroducing floating inputs

### 2. Missing snapshot coverage for one suite at the chosen timestamp

Risk:

- the reviewed timestamp may work for `debian` but not cleanly for `debian-security`

Mitigation:

- validate all required suites before accepting the timestamp
- split archive and security timestamps only if needed

### 3. Hidden dependency on `dist-upgrade`

Risk:

- one or more images may currently rely on side effects from `dist-upgrade`

Mitigation:

- convert `prebuild` first
- make any missing packages explicit in the Dockerfiles
- keep the rollout incremental so the first failure points directly at the missing declaration

### 4. `vccs` base-image mismatch

Risk:

- the Luna base may not match the shared Debian suite assumptions

Mitigation:

- verify the Luna base before forcing shared snapshot pins onto `vccs`
- keep `vccs` as an explicit exception if needed

## Done When

This work should be considered complete when all of the following are true:

- releng-owned Dockerfiles no longer install packages from live Debian mirrors
- releng-owned Dockerfiles no longer use `apt-get dist-upgrade`
- Debian package snapshot pins are reviewed and versioned in the repo
- the shared build path and Debian-based runtime images consume the same reviewed snapshot policy
- CI contains at least one focused check that rejects regression to floating apt inputs
- rebuilds from the same releng revision no longer change the Debian package set unless the reviewed snapshot pins were changed