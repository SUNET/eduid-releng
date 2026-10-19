include ../../versions/base-images.mk
include ../../versions/build-toolchain.mk

NODE_IMAGE := docker.io/library/node:$(NODE_MAJOR)-$(DEBIAN_VERSION)-slim
APT_REFRESH?=	$(VERSION)

docker:
	test -n '$(APT_REFRESH)' || exit 1
	docker build --pull \
	  --build-arg DEBIAN_VERSION="$(DEBIAN_VERSION)" \
	  --build-arg NODE_IMAGE="$(NODE_IMAGE)" \
	  --build-arg APT_REFRESH="$(APT_REFRESH)" \
	  --tag eduid-prebuild:latest .

.PHONY: docker
