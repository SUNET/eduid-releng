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
VCCS_LUNA_IMAGE_REPO := platform.sunet.se/keyforge/luna-base
VCCS_LUNA_IMAGE_TAG := trixie-10.9.4-123

# pyeleven Git source repository and tag.
# This source release reports package metadata version 0.0.1.
VCCS_PYELEVEN_SOURCE_REPO := git+https://github.com/IdentityPython/pyeleven.git
VCCS_PYELEVEN_SOURCE_VERSION := v0.0.2