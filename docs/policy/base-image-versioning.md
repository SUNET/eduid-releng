# Base Image Versioning Policy

## Purpose

Document where releng-owned image input review points live today.

## Source Of Truth

- `versions/base-images.mk`
- `versions/runtime-images.mk`
- `scripts/update-base-image-versions.sh`
- `scripts/update-runtime-image-versions.sh`

## Shared Debian Base

The Debian-based build and runtime images use:

- `DEBIAN_VERSION`
- `DEBIAN_DIGEST`

from `versions/base-images.mk`.

These values are the current releng-owned review point for shared Debian image identity.

## VCCS Runtime Base

`vccs` uses `VCCS_LUNA_IMAGE_TAG` from `versions/runtime-images.mk`.

That value is currently tag-based, not digest-based.

## Helper Targets

The root `Makefile` exposes:

- `show-base-image-versions`
- `check-base-image-versions`
- `update-base-image-versions`
- `show-runtime-image-versions`
- `check-runtime-image-versions`
- `update-runtime-image-versions`