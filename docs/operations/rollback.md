# Rollback Operations

## Purpose

Describe the rollback model implied by the current promotion design.

## Source Of Truth

- `Makefile`
- `images/*/Makefile`

## Current Rollback Model

This repository does not define deployment orchestration for running environments. It defines image build and image promotion.

That means rollback inside this repository is limited to image-tag operations.

## Practical Rollback Cases

### If a previous production tag should be re-used

Re-promote an older version that already exists at staging or testing using the same promotion targets:

```bash
make VERSION=<older-version> staging_release
make VERSION=<older-version> production_release
```

### If the deployment platform must revert

The actual runtime rollback step happens outside this repository and must be handled by the external deployment or operations system.

## Current Gap

There is no releng-owned digest-based rollback manifest or deployment-controller integration in this repository.