# ADR 0002: Build From Clean Source Exports

- Status: Accepted
- Date: 2021-03-03
- Type: Retrospective

## Context

Using submodules alone is not enough to guarantee clean build inputs. Building directly from working trees makes the result sensitive to local dirt, untracked files, and mutable checkout state.

The repository history shows an early move away from relying on local working-copy sources during the build.

## Decision

Export clean source snapshots from the submodules and build from those exports instead of building directly from in-place working trees.

In the current implementation, `build/Makefile` creates `build/sources/` using `git archive` and writes `revision.txt` files for each exported source tree.

## Consequences

Positive:

- build inputs are cleaner and easier to reason about
- exported trees can carry revision metadata alongside the build content
- releng reduces sensitivity to local untracked files inside submodule checkouts

Negative:

- the repository now has both submodule checkouts and generated export trees
- operators must understand that `build/sources/*` is generated content
- source export is an extra build stage to maintain and debug

## Evidence

- `397bd28` recorded the move away from needing local sources in the build path
- the current `build/Makefile` recreates `build/sources/` with `git archive`