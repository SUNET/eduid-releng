# Releng-owned build toolchain version pins.

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