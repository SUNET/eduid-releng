REPOS=		${CURDIR}/repos
SOURCES=	${CURDIR}/sources
INDEX=		$(WHEELS)/simple
VENV?=		"${HOME}/.virtualenvs/eduid-releng"
BRANCH=		ft-piptools_requirements

all:
	$(info --- INFO: Run 'make install' or 'make docker' ---)


# Export the submodules to clean source directories. This has to run outside of the docked build.
update:
	rm -rf $(SOURCES)
	mkdir -p $(SOURCES)
	ls -l $(REPOS)
	(cd $(REPOS)/eduid-backend && git archive --format=tar --prefix=eduid-backend/ HEAD) | (cd $(SOURCES) && tar xf -)
	cd $(REPOS)/eduid-backend && git show --summary > $(SOURCES)/eduid-backend/revision.txt

clean:
	rm -rf $(SOURCES)

# Essentially create the same venv twice, to have the option to massage them differently down the line
install:
	NAME=webapp ./setup-venv.sh
	NAME=worker ./setup-venv.sh
	NAME=falconapi ./setup-venv.sh

# The Dockerfile in this directory will execute 'make install' inside a build-image,
# and then initialise one or more virtualenvs under /opt/eduid using the setup-venv.sh script.
docker: update
	test -n '$(VERSION)' || exit 1
	docker build --build-arg "VERSION=$(VERSION)" --tag "eduid-build:$(VERSION)" .


.PHONY: update clean install docker
