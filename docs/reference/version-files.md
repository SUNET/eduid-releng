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
- `VCCS_PYELEVEN_SOURCE_REPO`
- `VCCS_PYELEVEN_SOURCE_VERSION`

`VCCS_LUNA_IMAGE_REPO` declares the repository, currently
`platform.sunet.se/keyforge/luna-base`. `VCCS_LUNA_IMAGE_TAG` selects the
mutable tag `trixie-10.9.4-123`. The VCCS Makefile combines them as
`repo:tag`, without a digest, for the Docker build argument
`VCCS_LUNA_IMAGE_REF`. The tag is also recorded in `/revision.txt`.

`VCCS_PYELEVEN_SOURCE_REPO` selects the Git source URL, currently
`git+https://github.com/IdentityPython/pyeleven.git`.
`VCCS_PYELEVEN_SOURCE_VERSION` selects the Git source tag, currently `v0.0.2`.
The VCCS Makefile passes both as Docker build arguments, and the Dockerfile
combines them as `source@version` for `uv pip install` into `/opt/eduid/fastapi`.
Both source values are also recorded in `/revision.txt`.
The upstream release reports package metadata version `0.0.1`; verify the
installed Git reference rather than relying on that metadata version alone.

### `versions/build-toolchain.mk`

Documents the current `uv` bootstrap policy.

It does not currently pin a reviewed `uv` version.