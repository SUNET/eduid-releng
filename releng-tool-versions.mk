# Releng-owned version pins.

# Debian base image pin used by releng-owned Debian-based Dockerfiles.
# Keep this aligned with the Python/runtime expectations of the current build.
DEBIAN_VERSION := trixie

# Luna client image tag used by the separate vccs runtime build path.
# Keep this aligned with the reviewed runtime contract for the Luna-backed image.
LUNA_IMAGE_VERSION := 10.9.0-0.0.2

# uv release pin used by the prebuild image and shared Python build path.
# Update these from https://github.com/astral-sh/uv/releases:
# - UV_VERSION: release tag
# - UV_RELEASE_ASSET: matching Linux tarball asset name
# - UV_RELEASE_SHA256: matching checksum line from the release's sha256.sum file
#
# Future suggestions:
# - dist-manifest.json may be used to discover the asset and cross-check metadata
# - download the GitHub release attestation JSON bundle for UV_RELEASE_ASSET
#   and verify the downloaded tarball with `gh attestation verify --bundle`
UV_VERSION := 0.11.16
UV_RELEASE_ASSET := uv-x86_64-unknown-linux-gnu.tar.gz
UV_RELEASE_SHA256 := 74947fe2c03315cf07e82ab3acc703eddef01aba4d5232a98e4c6825ec116131