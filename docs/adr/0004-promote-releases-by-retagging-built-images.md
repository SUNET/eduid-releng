# ADR 0004: Promote Releases By Retagging Built Images

- Status: Accepted
- Date: 2021-03-30
- Type: Retrospective

## Context

The repository needed a release flow that could move the same built artifact set across environments without rebuilding it for each promotion step.

The history shows an explicit decision to add persistent staging and production tags to already-built images.

## Decision

Promote releases by retagging existing images rather than rebuilding them for each environment.

In the current implementation, the root `Makefile` uses:

- `dockers_tagpush` for testing-tag publication
- `staging_release` to retag testing images as staging
- `production_release` to retag staging images as production

## Consequences

Positive:

- testing, staging, and production can all refer to the same built artifact set
- release promotion is separated from rebuild risk
- the release workflow is simpler to operate than environment-specific rebuilds

Negative:

- the current contract is tag-based rather than digest-based
- promotion logic must stay aligned across all service image Makefiles
- deployment-side rollback and rollout concerns still live outside this repository

## Evidence

- `6ae7cd5` added Makefile targets for staging and production tags
- the current top-level `Makefile` still implements tag-copy promotion targets