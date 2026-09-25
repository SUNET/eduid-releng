# Architecture Decision Records

This directory contains durable repo-level decisions that need more than inline documentation.

The current ADR set is retrospective: it summarizes decisions that can be traced through the repository history and are still visible in the current implementation.

## ADR Index

- [0001: Use Git Submodules For Release Inputs](0001-use-git-submodules-for-release-inputs.md)
- [0002: Build From Clean Source Exports](0002-build-from-clean-source-exports.md)
- [0003: Use A Staged Image Build For Shared Artifacts](0003-use-a-staged-image-build-for-shared-artifacts.md)
- [0004: Promote Releases By Retagging Built Images](0004-promote-releases-by-retagging-built-images.md)
- [0005: Keep VCCS As A Separate Runtime Build Path](0005-keep-vccs-as-a-separate-runtime-build-path.md)
- [0006: Scope Releng Image Inputs In Versions And Images](0006-scope-releng-image-inputs-in-versions-and-images.md)
- [0007: Use uv For Releng Python Environment Management](0007-use-uv-for-releng-python-environment-management.md)

## Notes

- ADRs describe durable decisions, not every historical change.
- When current implementation and an ADR diverge, update the ADR or add a new one that supersedes it.