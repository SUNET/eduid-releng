# Runtime image pins for service-specific container bases.

# Luna client image identity used by the separate vccs runtime build path.
#
# The underlying image is built in https://platform.sunet.se/keyforge/docker-luna-pyeleven.
# The selected tag identifies Debian trixie, Luna client 10.9.4-123,
# and the upstream pyeleven release label v0.0.2.
#
# Note: the included Luna HSM Client is proprietary software from Thales.
# It is not a publicly redistributable/open source dependency, and downloads
# are only available to authorized customers and partners with a registered
# account on the Thales Customer Support Portal.
#
# Keep the reviewed tag for operator readability. Tags are mutable and may
# resolve to a different image over time; this selection is not digest-pinned.
VCCS_LUNA_IMAGE_REPO := platform.sunet.se/keyforge/luna-pyeleven
VCCS_LUNA_IMAGE_TAG := trixie-10.9.4-123-v0.0.2