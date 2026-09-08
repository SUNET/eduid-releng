# ADR 0005: Keep VCCS As A Separate Runtime Build Path

- Status: Accepted
- Date: 2021-04-09
- Type: Retrospective

## Context

Most releng-managed Python services can share a common Debian-based runtime pattern and consume a prebuilt virtual environment from the shared build image.

`vccs` is different because it depends on a Luna client runtime base and HSM-related concerns that do not match the standard Debian-based service pattern.

## Decision

Keep `vccs` as an explicit runtime-path exception.

In the current implementation, `images/vccs/Dockerfile` starts from `VCCS_LUNA_IMAGE_REF` and builds its Python environment inside the final image instead of copying a shared prebuilt service environment from `eduid-build:$VERSION`.

## Consequences

Positive:

- releng can support a Luna-backed service without forcing the entire repository onto the same runtime base
- the VCCS-specific system dependencies and runtime wrapper logic remain isolated

Negative:

- `vccs` diverges from the common shared-venv path
- reproducibility and troubleshooting are harder because `vccs` has its own build behavior
- special-case documentation is required so maintainers do not assume the shared service pattern applies uniformly

## Evidence

- `7c81399`, `92a7928`, and related April 2021 history show the branch-driven introduction of VCCS
- the current `images/vccs/` directory still implements a separate runtime build path