docker:
	test -n $(VERSION) || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-webapp:$(VERSION)" .
	docker tag "eduid-webapp:$(VERSION)" "eduid-webapp:latest"

docker_tagpush:
	test -n $(VERSION) || exit 1
	test -n $(TAGSUFFIX) || exit 1
	docker tag "eduid-webapp:$(VERSION)" "docker.sunet.se/eduid/webapp:$(VERSION)-$(TAGSUFFIX)"
	docker push "docker.sunet.se/eduid/webapp:$(VERSION)-$(TAGSUFFIX)"

.PHONY: docker docker_tagpush
