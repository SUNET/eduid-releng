include ../../versions/base-images.mk

docker:
	test -n '$(VERSION)' || exit 1
	docker build \
	  --build-arg DEBIAN_DIGEST="$(DEBIAN_DIGEST)" \
	  --build-arg DEBIAN_VERSION="$(DEBIAN_VERSION)" \
	  --tag "eduid-runtime-common:$(VERSION)" .
	docker tag "eduid-runtime-common:$(VERSION)" eduid-runtime-common:latest

.PHONY: docker