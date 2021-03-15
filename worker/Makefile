docker:
	test -n $(VERSION) || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-worker:$(VERSION)" .
	docker tag "eduid-worker:$(VERSION)" "eduid-worker:latest"

docker_tagpush:
	test -n $(VERSION) || exit 1
	test -n $(TAGSUFFIX) || exit 1
	docker tag "eduid-worker:$(VERSION)" "docker.sunet.se/eduid/worker:$(VERSION)-$(TAGSUFFIX)"
	docker push "docker.sunet.se/eduid/worker:$(VERSION)-$(TAGSUFFIX)"

.PHONY: docker docker_tagpush
