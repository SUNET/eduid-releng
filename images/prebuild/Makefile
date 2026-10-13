include ../../versions/base-images.mk

APT_REFRESH?=	$(VERSION)

docker:
	test -n '$(APT_REFRESH)' || exit 1
	docker build --pull \
	  --build-arg DEBIAN_VERSION="$(DEBIAN_VERSION)" \
	  --build-arg APT_REFRESH="$(APT_REFRESH)" \
	  --tag eduid-prebuild:latest .

.PHONY: docker
