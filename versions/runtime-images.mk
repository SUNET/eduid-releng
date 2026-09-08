# Runtime image pins for service-specific container bases.

# Luna client image identity used by the separate vccs runtime build path.
#
# The underlying image is built in the https://github.com/SUNET/docker-luna-client/ repo,
# Upstream there tags images as # VERSION=$(LUNA)-$(PYELEVEN), so a tag like 10.9.0-0.0.2 means 
# Luna client 10.9.0 combined with pyeleven 0.0.2. 
# The upstream luna-client-10.9.0/deb.sh helper fetches and installs the vendor Luna client package for that build.
#
# Upstream semantic tags should be treated as mutable: that repo rebuilds with
# docker build --no-cache=true and uses floating inputs such as ubuntu:24.04,
# ghcr.io/astral-sh/uv:latest, and apt-get -y upgrade, so the same tag can
# resolve to a different image digest over time.

# Keep the reviewed tag for operator readability, but do not treat it as immutable.
VCCS_LUNA_IMAGE_TAG := 10.9.0-0.0.2