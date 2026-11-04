# ADR 0006: Scope Releng Image Inputs In Versions And Images

- Status: Accepted
- Date: 2026-05-29
- Type: Retrospective

## Context

As the repository accumulated more services, image-specific build logic, and reviewed input values, the earlier flatter layout became harder to reason about.

The history shows a deliberate restructuring that separated runtime image implementations from top-level clutter and moved releng-owned reviewed values into dedicated version files.

## Decision

Group image implementations under `images/` and releng-owned reviewed image input values under `versions/`.

In the current repository state:

- service and support image implementations live under `images/`
- shared Debian image identity is defined in `versions/base-images.mk`
- VCCS runtime identity is defined in `versions/runtime-images.mk`
- build-toolchain policy is documented separately in `versions/build-toolchain.mk`

## Consequences

Positive:

- runtime image assembly has a clear home in the repository tree
- reviewed image inputs are easier to find and reason about
- repo structure matches the release-engineering domain more clearly

Negative:

- path changes require coordinated updates to Makefiles, docs, and helper scripts
- the `build/` subtree still mixes build logic, submodules, and generated exports despite the broader cleanup

## Evidence

- `c1c9976` reorganized runtime image implementation under `images/` and review files under `versions/`
- `3667678`, `19b4c12`, and `81844f0` further refined scoped version management afterward