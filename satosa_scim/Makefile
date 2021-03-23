docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-satosa_scim:$(VERSION)" .
	docker tag "eduid-satosa_scim:$(VERSION)" "eduid-satosa_scim:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-satosa_scim:$(VERSION)" "docker.sunet.se/eduid/satosa_scim:$(VERSION)-$(TAGSUFFIX)"
	docker push "docker.sunet.se/eduid/satosa_scim:$(VERSION)-$(TAGSUFFIX)"

.PHONY: docker docker_tagpush
