docker:
	test -n $(VERSION) || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-worker:$(VERSION)" .
	docker tag "eduid-worker:$(VERSION)" "eduid-worker:latest"
