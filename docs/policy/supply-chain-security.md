# Supply-Chain Security Policy

## Purpose

Describe the current supply-chain posture of this repository and the main gaps that still matter.

## Source Of Truth

- `.forgejo/workflows/build-action.yaml`
- `versions/base-images.mk`
- `versions/runtime-images.mk`
- `images/prebuild/Dockerfile`

## Current Strengths

- reviewed base-image inputs exist for Debian-based images
- a reviewed Luna runtime tag exists for `vccs`
- backend requirements are installed with hash checking
- the build records useful provenance breadcrumbs through `revision.txt` and `build/submodules.txt`

## Current Gaps

- the CI path disables BuildKit
- the repo does not produce first-class SBOMs or provenance attestations
- promotion is tag-based rather than digest-based
- `uv` is bootstrapped from `pip` without a releng pin
- Debian package resolution remains mutable at build time

## Policy Direction

The next supply-chain improvements should favor:

1. immutable release inputs
2. digest-aware promotion
3. provenance and SBOM generation
4. removal of avoidable floating build inputs