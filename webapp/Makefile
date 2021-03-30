DOCKERIMAGE?=	docker.sunet.se/eduid/webapp

docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-webapp:$(VERSION)" .
	docker tag "eduid-webapp:$(VERSION)" "eduid-webapp:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-webapp:$(VERSION)" "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker pull "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)"
	docker tag "$(DOCKERIMAGE):$(VERSION)-$(SRCTAG)" "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"
	docker push "$(DOCKERIMAGE):$(VERSION)-$(DSTTAG)"

.PHONY: docker docker_tagpush tag_copypush
