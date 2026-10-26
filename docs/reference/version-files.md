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

This selects a mutable Debian codename tag, without an image digest pin.

### `versions/runtime-images.mk`

Owns service-specific runtime base review values:

- `VCCS_LUNA_IMAGE_REPO`
- `VCCS_LUNA_IMAGE_TAG`

`VCCS_LUNA_IMAGE_REPO` declares the repository, currently
`platform.sunet.se/keyforge/luna-base`. `VCCS_LUNA_IMAGE_TAG` selects the
mutable tag `trixie-10.9.4-123`. The VCCS Makefile combines them as
`repo:tag`, without a digest, for the Docker build argument
`VCCS_LUNA_IMAGE_REF`. The tag is also recorded in `/revision.txt`.

### `versions/build-toolchain.mk`

Owns the frontend build toolchain image selection:

- `NODE_MAJOR`

This is an explicit releng policy value. It is not derived from upstream
engine requirements; changing the major requires a reviewed policy update
and compatibility validation of both frontend projects.

The prebuild Makefile combines this major with `DEBIAN_VERSION` from
`versions/base-images.mk` to form
`docker.io/library/node:<major>-<debian>-slim`, currently
`docker.io/library/node:24-trixie-slim`. Docker builds use `--pull` to refresh
the latest published minor/patch for that major and Debian variant, keeping
the image's bundled npm. No resolver, host Node.js, or digest pin is required.
The moving tag does not guarantee identical toolchain versions across builds.
An explicit `NODE_IMAGE=<image:tag>` Make argument overrides the composed tag.

The file also documents the current `uv` bootstrap policy, without pinning a
reviewed `uv` version.