include ../../versions/base-images.mk

REGISTRY?=	platform.sunet.se
DOCKERIMAGE?=	$(REGISTRY)/eduid/worker

docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --build-arg "DEBIAN_VERSION=$(DEBIAN_VERSION)" --build-arg "DEBIAN_DIGEST=$(DEBIAN_DIGEST)" --tag "eduid-worker:$(VERSION)" .
	docker tag "eduid-worker:$(VERSION)" "eduid-worker:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-worker:$(VERSION)" "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker pull "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)"
	docker tag "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)" "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"

.PHONY: docker docker_tagpush tag_copypush
