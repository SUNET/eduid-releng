docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-falconapi:$(VERSION)" .
	docker tag "eduid-falconapi:$(VERSION)" "eduid-falconapi:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-falconapi:$(VERSION)" "docker.sunet.se/eduid/falconapi:$(VERSION)-$(TAGSUFFIX)"
	docker push "docker.sunet.se/eduid/falconapi:$(VERSION)-$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker tag "docker.sunet.se/eduid/webapp:$(VERSION)-$(SRCTAG)" "docker.sunet.se/eduid/webapp:$(VERSION)-$(DSTTAG)"
	docker push "docker.sunet.se/eduid/webapp:$(VERSION)-$(DSTTAG)"

.PHONY: docker docker_tagpush tag_copypush
