# Version Files Reference

## Purpose

Show which version files exist today and what they control.

## Source Of Truth

- `versions/base-images.mk`
- `versions/runtime-images.mk`
- `versions/build-toolchain.mk`

## Current Files

### `versions/base-images.mk`

Owns the shared Debian base identity for Debian-based images:

- `DEBIAN_VERSION`
- `DEBIAN_DIGEST`

### `versions/runtime-images.mk`

Owns service-specific runtime base review values:

- `VCCS_LUNA_IMAGE_TAG`

### `versions/build-toolchain.mk`

Documents the current `uv` bootstrap policy.

It does not currently pin a reviewed `uv` version.