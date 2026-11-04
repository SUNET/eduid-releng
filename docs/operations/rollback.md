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

For versioned images, re-promote an older version that still exists at staging:

```bash
make VERSION=<older-version> production_release
```

If that version exists only at testing, promote it to staging first:

```bash
make VERSION=<older-version> staging_release
make VERSION=<older-version> production_release
```

Both targets also promote `admintools`, whose registry tags are unversioned.
An older `VERSION` does not recover an overwritten `admintools` image. Verify
its source tag separately before using these all-image targets; they can
otherwise promote a newer administrative image alongside the older release.

If the intended versioned production tags already exist, the deployment
platform can reuse them without another promotion.

### If the deployment platform must revert

The actual runtime rollback step happens outside this repository and must be handled by the external deployment or operations system.

## Current Gap

There is no releng-owned digest-based rollback manifest or deployment-controller integration in this repository.