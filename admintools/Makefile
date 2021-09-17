DOCKERIMAGE?=	docker.sunet.se/eduid/admintools

docker:
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-admintools:$(VERSION)" .
y	docker tag "eduid-admintools:$(VERSION)" "eduid-admintools:latest"

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
        # No $(VERISON) in the output tag name for admintools!
	docker tag "eduid-admintools:$(VERSION)" "$(DOCKERIMAGE):$(TAGSUFFIX)"
	docker push "$(DOCKERIMAGE):$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker pull "$(DOCKERIMAGE):$(SRCTAG)"
        # No $(VERISON) in the tag name for admintools!
	docker tag "$(DOCKERIMAGE):$(SRCTAG)" "$(DOCKERIMAGE):$(DSTTAG)"
	docker push "$(DOCKERIMAGE):$(DSTTAG)"

.PHONY: docker docker_tagpush tag_copypush

