# Repository Structure Analysis And Proposal

## Purpose

This note analyzes the current repository structure from a release-engineering point of view and proposes a clearer folder layout.

It complements `SIMPLIFICATION_PLAN.md`. That document focuses mainly on duplication and shared implementation. This note focuses on directory boundaries, ownership, and where different kinds of releng logic should live.

## Scope

This proposal is about the releng repository itself.

It is not a proposal to restructure the upstream application repositories under `build/repos/`, and it is not a proposal to manually rearrange generated content under `build/sources/`.

## Current Structure Summary

Today the repository root contains several different categories of content side by side:

1. Top-level orchestration and version pins.
2. Shared build logic and source export logic.
3. Per-image implementation directories.
4. Small maintenance scripts.
5. Operational and design documentation.
6. Imported upstream source checkouts and generated source exports.

In simplified form, the current layout is:

```text
/
  Makefile
  build-toolchain-versions.mk
  base-image-versions.mk
  runtime-image-versions.mk
  build/
  images/prebuild/
  images/webapp/
  images/worker/
  images/fastapi/
  images/satosa_scim/
  images/admintools/
  images/html/
  images/vccs/
  scripts/
  docs/
```

This structure works, but it asks the reader to infer which directories are orchestration, which are shared build layers, and which are service-specific runtime images.

## What Is Already Structurally Sound

Not everything should move.

The following current boundaries are reasonable and should remain explicit:

### `build/repos/`

This is the upstream source input boundary. These are git submodules and do not belong to releng in the same way the rest of the repository does.

### `build/sources/`

This is the clean exported-source boundary produced by releng. It is generated content and should remain clearly separate from both releng logic and upstream checkouts.

### `build/`

This is the artifact-factory layer. It contains source export logic, frontend builds, and Python virtualenv preparation. That is a coherent responsibility.

### `docs/`

Operational and design documentation already has a dedicated home. The current `docs/notes/` subdivision is a reasonable place for analysis and working proposals.

## Structural Problems In The Current Layout

### 1. The root is overloaded

The repository root currently mixes:

- release entry points
- version-pin files
- service image implementations
- shared build directories
- documentation

That makes the root look flatter than the architecture actually is.

### 2. Service implementations are treated as root-level peers of orchestration

Directories such as `images/webapp/`, `images/worker/`, `images/fastapi/`, `images/admintools/`, and `images/html/` are implementation details of the runtime image layer, but today they sit next to the repo's main orchestration files.

That makes the repo feel like a collection of loosely related projects instead of one releng system with a runtime-image subsystem.

### 3. Shared releng logic has no obvious home

The repository has repeated Make logic and repeated runtime-shell patterns, but no clear structural home for shared Make includes or shared shell libraries.

As a result, duplication tends to stay in place because there is nowhere obvious to move it.

### 4. Version review points are top-level but not grouped

The files:

- `build-toolchain-versions.mk`
- `base-image-versions.mk`
- `runtime-image-versions.mk`

are conceptually related, but they are currently scattered across the root as separate top-level concerns.

### 5. The current structure hides the pipeline shape

The actual pipeline is roughly:

1. select submodule revisions
2. export clean sources
3. build shared artifacts
4. assemble runtime images
5. tag and promote releases

The current folder structure only partially reflects that flow. The runtime-image layer is especially under-modeled.

## Design Goals For A Better Structure

Any improvement should preserve the current release behavior while making the repository easier to navigate.

The structure should make these distinctions visible:

1. orchestration versus implementation
2. shared releng logic versus service-specific exceptions
3. source inputs versus generated outputs
4. version review data versus executable build logic
5. stable pipeline boundaries versus one-off service details

## Proposed Target Structure

The repository should converge toward a structure like this:

```text
/
  Makefile
  README.md
  orchestration/
    services.mk
    service-image.mk
    release.mk
  versions/
    build-toolchain.mk
    base-images.mk
    runtime-images.mk
  build/
    Makefile
    setup-venv.sh
    build-js.sh
    repos/
    sources/
  images/
    images/prebuild/
    images/webapp/
    images/worker/
    images/fastapi/
    images/satosa_scim/
    images/admintools/
    images/html/
    images/vccs/
  scripts/
  docs/
    notes/
```

This proposal uses three structural ideas.

### A. Put shared Make logic under `orchestration/`

This gives the repository one explicit place for releng metadata and reusable orchestration logic.

Suggested responsibilities:

- `orchestration/services.mk`: service catalog and shared metadata
- `orchestration/service-image.mk`: common per-service image build, tag, push, and retag rules
- `orchestration/release.mk`: root-level multi-service orchestration rules

### B. Group reviewed version pins under `versions/`

These files are not service implementations. They are reviewed release inputs. A dedicated directory would make that clear.

Suggested mapping:

- `build-toolchain-versions.mk` -> `versions/build-toolchain.mk`
- `base-image-versions.mk` -> `versions/base-images.mk`
- `runtime-image-versions.mk` -> `versions/runtime-images.mk`

### C. Group runtime image implementations under `images/`

The current service directories are all part of the same subsystem: runtime image assembly.

Moving them under `images/` would make the repo layout reflect the architecture more directly.

That includes:

- `images/prebuild/`
- `images/webapp/`
- `images/worker/`
- `images/fastapi/`
- `images/satosa_scim/`
- `images/admintools/`
- `images/html/`
- `images/vccs/`

## Why This Structure Is Better

### Clearer navigation

A new reader can infer the repo shape faster:

- root: entry points and high-level description
- `orchestration/`: shared releng rules
- `versions/`: reviewed version inputs
- `build/`: artifact production
- `images/`: final image assembly
- `docs/`: operational documentation

### Better separation of concerns

The proposal makes it obvious which files describe release policy and which files implement individual runtime images.

### Easier refactoring

Adding `orchestration/` creates a destination for deduplicated Make logic. Without that, repeated rules tend to remain copied across directories.

### Easier service changes

When all image implementations live under `images/`, service-specific changes are less likely to look like root-level infrastructure changes.

### Less accidental root sprawl

The root remains reserved for the small set of files that actually define the repository entry points.

## What Should Not Change Immediately

This proposal should not be executed as a large mechanical move in one step.

The following boundaries should remain stable in early phases:

1. `build/repos/` as the submodule input boundary.
2. `build/sources/` as the generated export boundary.
3. The top-level `Makefile` as the user-facing entry point.
4. Existing release target names such as `dockers`, `dockers_tagpush`, `staging_release`, and `production_release`.

Those are user-facing or pipeline-facing interfaces. The structure can improve without changing them.

## Recommended Migration Strategy

The safest way to improve the structure is to separate logical restructuring from physical moves.

### Phase 1: Create logical homes without moving service directories

Add:

- `orchestration/`
- `versions/`

Move shared include logic and version includes first, while keeping current service paths stable.

This phase should do the following:

1. Introduce `orchestration/services.mk` and move service lists and service metadata there.
2. Introduce `orchestration/release.mk` and move repeated orchestration loops there.
3. Introduce `orchestration/service-image.mk` and refactor service Makefiles to include shared rules.
4. Move version-pin includes into `versions/` and update include paths.

Expected benefit:

The repository gains a clearer logical structure before any wide path changes are introduced.

### Phase 2: Move runtime image directories under `images/`

After the Make logic is centralized, move:

- `images/prebuild/`
- `images/webapp/`
- `images/worker/`
- `images/fastapi/`
- `images/satosa_scim/`
- `images/admintools/`
- `images/html/`
- `images/vccs/`

under `images/`.

This phase becomes much lower risk once shared Make logic has been extracted, because path updates are then concentrated in fewer files.

### Phase 3: Optional shared runtime-library extraction

Once the folder layout makes subsystem boundaries clearer, extract repeated shell logic into a shared runtime library under a path such as:

- `scripts/lib/runtime-common.sh`
- or `images/lib/runtime-common.sh`

This is optional for the folder-structure change itself, but the new structure makes it easier to do cleanly.

## Risks And Tradeoffs

### Risk: path churn

A large directory move can break relative includes, `docker build` contexts, and CI scripts. That is why path moves should come after Make-level centralization.

### Risk: over-generalizing exceptions

`html`, `admintools`, `satosa_scim`, and `vccs` have real differences. The structure should make exceptions explicit, not force them into a fake uniform model.

### Tradeoff: one more directory layer

Adding `images/`, `orchestration/`, and `versions/` introduces slightly deeper paths. That is acceptable because the gain in clarity is larger than the cost in path length.

## Concrete First Step

If only one structural improvement is made first, it should be this:

1. add `orchestration/`
2. add `versions/`
3. centralize service and release metadata
4. keep current service directories where they are for now

That delivers most of the structural clarity with minimal operational disruption.

## Recommendation

The repository can have a better folder structure, but the right first move is not to drag directories around the tree.

The right first move is to create explicit homes for:

- shared Make metadata
- shared release rules
- reviewed version inputs

After that, move the service-image directories under `images/` in a controlled step.

In short:

- keep `build/` as the source-export and artifact-build boundary
- keep `build/repos/` and `build/sources/` exactly conceptually separate
- introduce `orchestration/` for shared releng logic
- introduce `versions/` for reviewed pins
- move service image implementations under `images/` only after the logical refactor is complete

## Validation To Use When Implementing This Proposal

If this proposal is executed in code, the narrow validation set should be:

1. `make -n dockers`
2. `make -n dockers_tagpush VERSION=test`
3. `make -n staging_release VERSION=test`
4. `make -n production_release VERSION=test`
5. targeted `make -n webapp` and `make -n vccs`

Those checks are sufficient to catch most path and orchestration regressions before any real image builds are attempted.