include ../../versions/runtime-images.mk

REGISTRY?=	platform.sunet.se
DOCKERIMAGE?=	$(REGISTRY)/eduid/vccs
APT_REFRESH?=	$(VERSION)

docker:
	test -n '$(VERSION)' || exit 1
	test -n '$(APT_REFRESH)' || exit 1
	test -n '$(VCCS_LUNA_IMAGE_REPO)' || exit 1
	test -n '$(VCCS_LUNA_IMAGE_TAG)' || exit 1
	test -n '$(VCCS_PYELEVEN_SOURCE_REPO)' || exit 1
	test -n '$(VCCS_PYELEVEN_SOURCE_VERSION)' || exit 1
	docker pull "$(VCCS_LUNA_IMAGE_REPO):$(VCCS_LUNA_IMAGE_TAG)"
	# Use images/ as context to copy the shared FastAPI launcher; select VCCS's Dockerfile explicitly.
	docker build --file Dockerfile --build-arg "VERSION=$(VERSION)" --build-arg APT_REFRESH="$(APT_REFRESH)" --build-arg "VCCS_LUNA_IMAGE_REF=$(VCCS_LUNA_IMAGE_REPO):$(VCCS_LUNA_IMAGE_TAG)" --build-arg "VCCS_LUNA_IMAGE_TAG=$(VCCS_LUNA_IMAGE_TAG)" --build-arg "VCCS_PYELEVEN_SOURCE_REPO=$(VCCS_PYELEVEN_SOURCE_REPO)" --build-arg "VCCS_PYELEVEN_SOURCE_VERSION=$(VCCS_PYELEVEN_SOURCE_VERSION)" --tag "eduid-vccs:$(VERSION)" ..
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
