include ../build-toolchain-versions.mk
include ../base-image-versions.mk

docker:
	docker images | grep -q eduid-prebuild || docker build \
	  --build-arg DEBIAN_VERSION="$(DEBIAN_VERSION)" \
	  --build-arg UV_VERSION="$(UV_VERSION)" \
	  --build-arg UV_RELEASE_ASSET="$(UV_RELEASE_ASSET)" \
	  --build-arg UV_RELEASE_SHA256="$(UV_RELEASE_SHA256)" \
	  --tag eduid-prebuild:latest .
