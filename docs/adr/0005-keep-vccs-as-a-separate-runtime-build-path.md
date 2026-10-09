# ADR 0005: Keep VCCS As A Separate Runtime Build Path

- Status: Accepted
- Date: 2021-04-09
- Type: Retrospective

## Context

Most releng-managed Python services can share a common Debian-based runtime pattern and consume a prebuilt virtual environment from the shared build image.

`vccs` is different because it depends on a Luna client runtime base and HSM-related concerns that do not match the standard Debian-based service pattern.

## Decision

Keep `vccs` as an explicit runtime-path exception.

In the current implementation, `images/vccs/Dockerfile` starts from
`VCCS_LUNA_IMAGE_REF` and copies the shared FastAPI environment from
`eduid-build:$VERSION`. The runtime-base exception does not require a separate
Python dependency build. Debian packages in the Luna-based image provide the
runtime interpreter.

## Consequences

Positive:

- releng can support a Luna-backed service without forcing the entire repository onto the same runtime base
- the VCCS-specific system dependencies and runtime wrapper logic remain isolated

Negative:

- the external Luna base must remain compatible with the shared venv's Python
	version and native dependencies
- reproducibility and troubleshooting still depend on the separately reviewed
	Luna base and its runtime packages
- special-case documentation is required so maintainers do not assume the shared service pattern applies uniformly

## Evidence

- `7c81399`, `92a7928`, and related April 2021 history show the branch-driven introduction of VCCS
- the current `images/vccs/` directory still implements a separate runtime build path