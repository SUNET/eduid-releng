docker:
	test -n $(VERSION) || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-webapp:$(VERSION)" .
	docker tag "eduid-webapp:$(VERSION)" "eduid-webapp:latest"
