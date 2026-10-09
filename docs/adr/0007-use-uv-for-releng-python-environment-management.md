# ADR 0007: Use uv For Releng Python Environment Management

- Status: Accepted
- Date: 2026-05-27
- Type: Retrospective

## Context

The repository historically managed Python environments through older `pip`-oriented flows that left more room for mutable bootstrap behavior.

The 2026 history shows a deliberate move toward `uv` for environment creation and package installation, followed by a refinement that kept Python interpreter provenance in the image layer rather than delegating it to `uv`.

## Decision

Use `uv` as the releng Python environment manager while keeping Python binaries supplied by the image or OS layer.

In the current implementation:

- `build/setup-venv.sh` uses `uv venv` and `uv pip install --require-hashes`
- `images/prebuild/Dockerfile` bootstraps `uv` with `pip`
- releng sets `UV_PYTHON_DOWNLOADS=never`

## Consequences

Positive:

- shared Python environment creation is more consistent across services
- hash-locked requirements are enforced in the shared build path
- interpreter provenance remains tied to the selected image base rather than a `uv` download decision

Negative:

- `uv` is still intentionally unpinned in current releng policy
- the separate `setuptools` bootstrap remains a floating input in the shared path
- `vccs` still diverges from the common shared-venv implementation details

## Evidence

- `8f57ce1` switched Python install paths to `uv`
- `07004ce` refined the shared Python environment flow to the current bootstrap model
- the current `build/setup-venv.sh`, `images/prebuild/Dockerfile`, and `versions/build-toolchain.mk` still reflect this decision