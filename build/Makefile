REPOS=		${CURDIR}/repos
SOURCES=	${CURDIR}/sources
WHEELS=		${CURDIR}/wheels
INDEX=		$(WHEELS)/simple
VENV?=		"${HOME}/.virtualenvs/eduid-releng"
BRANCH=		ft-piptools_requirements

update:
	rm -rf sources; rsync -a repos/ sources

clean:
	rm -rf wheels
	mkdir wheels

venv:
	python3 -mvenv $(VENV)
	$(VENV)/bin/pip install wheel pip-tools piprepo
	$(VENV)/bin/pip install --extra-index https://pypi.sunet.se/simple pysmscom vccs-client

build: clean update venv
	test -n $(VERSION) || exit 1
	VENV=$(VENV) SOURCES=$(SOURCES) VERSION="$(VERSION)" ./build.sh

wheels: build
	cp -ia $(SOURCES)/*/dist/*whl $(WHEELS) || true
	$(VENV)/bin/piprepo build $(WHEELS)

# The Dockerfile in this directory will execute 'make wheels' inside a build-image,
# and then initialise one or more virtualenvs under /opt/eduid using the setup-venv.sh script.
docker:
	test -n $(VERSION) || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-build:$(VERSION)" .

all: venv wheels
