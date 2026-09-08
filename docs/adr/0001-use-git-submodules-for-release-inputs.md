# ADR 0001: Use Git Submodules For Release Inputs

- Status: Accepted
- Date: 2021-03-02
- Type: Retrospective

## Context

This repository assembles a release from several upstream eduID repositories rather than owning all application code directly.

It needed a repository-level way to track which upstream revisions belong to a release while keeping the upstream source trees separate from releng-owned code.

The earliest clear implementation choice was to add upstream repositories as git submodules.

## Decision

Use git submodules as the release-input mechanism for upstream eduID repositories.

In the current repository state, those submodules live under `build/repos/` and are updated through top-level Make targets such as `build_prep` and `update_what_to_build`.

## Consequences

Positive:

- releng can pin and review exact upstream commits through the main repository
- upstream repositories remain separately owned and versioned
- releng can assemble a coordinated multi-repo release without copying application history into this repository

Negative:

- release input selection is tied to submodule update workflows and branch movement
- local operations become more complex than a single-repository build
- releng must clearly document that `build/repos/*` is upstream-owned, not releng-owned

## Evidence

- `d3f3325` introduced the initial submodule setup
- the current `Makefile` still uses submodule-oriented targets and workflows