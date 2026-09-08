include ../../versions/base-images.mk

docker:
	docker images | grep -q eduid-prebuild || docker build \
	  --build-arg DEBIAN_DIGEST="$(DEBIAN_DIGEST)" \
	  --build-arg DEBIAN_VERSION="$(DEBIAN_VERSION)" \
	  --tag eduid-prebuild:latest .
