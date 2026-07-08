REGISTRY?=	platform.sunet.se
DOCKERIMAGE?=	$(REGISTRY)/eduid/vccs

docker:
	test -n '$(VERSION)' || exit 1
	test -n '$(VCCS_LUNA_IMAGE_TAG)' || exit 1
	test -n '$(VCCS_LUNA_IMAGE_DIGEST)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --build-arg "VCCS_LUNA_IMAGE_REF=docker.sunet.se/luna-client:$(VCCS_LUNA_IMAGE_TAG)@$(VCCS_LUNA_IMAGE_DIGEST)" --build-arg "VCCS_LUNA_IMAGE_TAG=$(VCCS_LUNA_IMAGE_TAG)" --build-arg "VCCS_LUNA_IMAGE_DIGEST=$(VCCS_LUNA_IMAGE_DIGEST)" --tag "eduid-vccs:$(VERSION)" .
	docker tag "eduid-vccs:$(VERSION)" "eduid-vccs:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-vccs:$(VERSION)" "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker pull "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)"
	docker tag "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)" "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"

.PHONY: docker docker_tagpush tag_copypush
