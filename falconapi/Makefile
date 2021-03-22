docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-falconapi:$(VERSION)" .
	docker tag "eduid-falconapi:$(VERSION)" "eduid-falconapi:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "eduid-falconapi:$(VERSION)" "docker.sunet.se/eduid/falconapi:$(VERSION)-$(TAGSUFFIX)"
	docker push "docker.sunet.se/eduid/falconapi:$(VERSION)-$(TAGSUFFIX)"

.PHONY: docker docker_tagpush
