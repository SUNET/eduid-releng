# Runtime image pins for service-specific container bases.

# Luna client image identity used by the separate vccs runtime build path.
#
# The underlying image is built in https://platform.sunet.se/keyforge/docker-luna-base.
# The selected tag identifies Debian trixie and Luna client 10.9.4-123.
#
# Note: the included Luna HSM Client is proprietary software from Thales.
# It is not a publicly redistributable/open source dependency, and downloads
# are only available to authorized customers and partners with a registered
# account on the Thales Customer Support Portal.
#
# Keep the reviewed tag for operator readability. Tags are mutable and may
# resolve to a different image over time; this selection is not digest-pinned.
#
# Coupling: the Debian release in VCCS_LUNA_IMAGE_TAG must match DEBIAN_VERSION
# (versions/base-images.mk). The vccs image runs a venv built on the eduid-build
# image (debian:$(DEBIAN_VERSION)) with this image's python3, so a mismatch breaks
# the venv's Python minor version and native library compatibility at runtime.
VCCS_LUNA_IMAGE_REPO := platform.sunet.se/keyforge/luna-base
VCCS_LUNA_IMAGE_TAG := trixie-10.9.4-123