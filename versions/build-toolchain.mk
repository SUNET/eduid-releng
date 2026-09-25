# Releng-owned build toolchain policy.
#
# uv is the official Python environment manager for releng builds, but it is not
# used to supply Python binaries. The build images provide python3, and releng
# configures uv with UV_PYTHON_DOWNLOADS=never to keep interpreter provenance in
# the image layer.
#
# For now, uv is intentionally installed from pip as the latest available
# version, with no releng pin, digest check, or checksum verification.