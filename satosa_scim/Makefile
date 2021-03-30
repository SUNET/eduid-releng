docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-satosa_scim:$(VERSION)" .
	docker tag "eduid-satosa_scim:$(VERSION)" "eduid-satosa_scim:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-satosa_scim:$(VERSION)" "docker.sunet.se/eduid/satosa_scim:$(VERSION)-$(TAGSUFFIX)"
	docker push "docker.sunet.se/eduid/satosa_scim:$(VERSION)-$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker tag "docker.sunet.se/eduid/webapp:$(VERSION)-$(SRCTAG)" "docker.sunet.se/eduid/webapp:$(VERSION)-$(DSTTAG)"
	docker push "docker.sunet.se/eduid/webapp:$(VERSION)-$(DSTTAG)"

.PHONY: docker docker_tagpush tag_copypush

