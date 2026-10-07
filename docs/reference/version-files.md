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

- `VCCS_LUNA_IMAGE_REPO`
- `VCCS_LUNA_IMAGE_TAG`

`VCCS_LUNA_IMAGE_REPO` declares the repository, currently
`platform.sunet.se/keyforge/luna-pyeleven`. `VCCS_LUNA_IMAGE_TAG` selects the
mutable tag `trixie-10.9.4-123-v0.0.2`. The VCCS Makefile combines them as
`repo:tag`, without a digest, for the Docker build argument
`VCCS_LUNA_IMAGE_REF`. The tag is also recorded in `/revision.txt`.

### `versions/build-toolchain.mk`

Documents the current `uv` bootstrap policy.

It does not currently pin a reviewed `uv` version.