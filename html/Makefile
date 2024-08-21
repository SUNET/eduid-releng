DOCKERIMAGE?=	docker.sunet.se/eduid/html

docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-html:$(VERSION)" .
	docker tag "eduid-html:$(VERSION)" "eduid-html:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-html:$(VERSION)" "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker pull "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)"
	docker tag "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)" "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"

.PHONY: docker docker_tagpush tag_copypush
