# ADR 0003: Use A Staged Image Build For Shared Artifacts

- Status: Accepted
- Date: 2021-03-03
- Type: Retrospective

## Context

The repository builds several runtime images that share a large amount of build-time setup and generated content.

Building every runtime image independently from scratch would duplicate dependency installation, frontend build work, and Python environment creation.

## Decision

Use a staged image build model:

1. build a shared prebuild image with common toolchain dependencies
2. build an intermediate `eduid-build:$VERSION` image that produces reusable artifacts
3. assemble runtime images by copying the relevant artifacts from the intermediate image

The current implementation expresses this through `make prebuild`, `make build`, and the runtime image targets.

## Consequences

Positive:

- shared build logic and dependencies are centralized
- runtime images can reuse prebuilt Python environments and frontend bundles
- the artifact flow is easier to standardize across multiple services

Negative:

- the pipeline becomes multi-stage and harder to understand without documentation
- compatibility between build-stage outputs and runtime-stage bases must be maintained carefully
- special cases such as `vccs` stand out more sharply when they do not follow the shared pattern

## Evidence

- early 2021 history introduced separate runtime images and shared build mechanics
- the current `Makefile`, `images/prebuild/`, and `build/` directories still implement this staged model