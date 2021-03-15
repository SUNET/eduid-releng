REPOS=		${CURDIR}/build/repos
SOURCES=	${CURDIR}/sources
WHEELS=		${CURDIR}/wheels
INDEX=		$(WHEELS)/simple
VENV?=		"${HOME}/.virtualenvs/eduid-releng"
TAGSUFFIX?=	testing
BRANCH=		origin/main
SUBMODULES=	eduid-backend
DATETIME:=	$(shell date -u +%Y%m%dT%H%M%S)
VERSION?=       $(DATETIME)

update:
	git submodule update --init
	git submodule update
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"

pull_submodules: update
	git submodule foreach "git fetch origin"
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"

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

dockers_tagpush:
	cd webapp && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd worker && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush

all: dockers

.PHONY: prebuild build webapp worker
