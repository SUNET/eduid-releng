REPOS=		${CURDIR}/repos
SOURCES=	${CURDIR}/sources
WHEELS=		${CURDIR}/wheels
INDEX=		$(WHEELS)/simple
VENV?=		"${HOME}/.virtualenvs/eduid-releng"
BRANCH=		ft-piptools_requirements
SUBMODULES=	eduid-am eduid-common eduid-graphdb eduid-lookup-mobile eduid_msg eduid-userdb eduid-queue eduid-scimapi eduid-webapp
DATETIME:=	$(shell date -u +%Y%m%dT%H%M%S)
VERSION?=       $(DATETIME)

update:
	git submodule update --init
	git submodule update
	git submodule foreach 'git reset --hard'
	git submodule foreach 'git checkout master || git checkout main'
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"
	git submodule foreach "ls -l"

deinit_submodules:
	cd ${REPOS} && for mod in $(SUBMODULES); do git submodule deinit -f $${mod}; done

init_submodules:
	mkdir -p "${REPOS}"
	cd "${REPOS}"; for mod in $(SUBMODULES); do git submodule add https://github.com/SUNET/$${mod}.git; done

real_clean: clean init_submodules

prebuild:
	cd prebuild && make docker

build: update prebuild
	git submodule status > build/submodules.txt
	cd build && make VERSION=$(VERSION) docker

webapp:
	cd webapp && make VERSION=$(VERSION) docker

worker:
	cd worker && make VERSION=$(VERSION) docker

dockers: build webapp worker

all: dockers

.PHONY: prebuild build webapp worker
