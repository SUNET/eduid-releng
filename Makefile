REPOS=		${CURDIR}/build/repos
SOURCES=	${CURDIR}/sources
WHEELS=		${CURDIR}/wheels
INDEX=		$(WHEELS)/simple
VENV?=		"${HOME}/.virtualenvs/eduid-releng"
TAGSUFFIX?=	testing
BRANCH=		origin/main
SUBMODULES=	eduid-backend
DOCKERS=        webapp worker falconapi satosa_scim
DATETIME:=	$(shell date -u +%Y%m%dT%H%M%S)
VERSION?=       $(DATETIME)

all:
	$(info --- INFO: eduID release engineering ---)
	$(info ---)
	$(info --- INFO: The main targets of this Makefile are: )
	$(info ---)
	$(info ---         update_what_to_build: Update what code will be built to the upstream branch $(BRANCH) ---)
	$(info ---         dockers:              Build docker images $(DOCKERS) ---)
	$(info ---)

build_prep:
	git submodule update --init
	git submodule update
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"

update_what_to_build: build_prep
	git submodule foreach "git fetch origin"
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"
	git commit -m "updated eduid-releng submodule to branch ${BRANCH}" build/repos/eduid-backend

deinit_submodules:
	cd ${REPOS} && for mod in $(SUBMODULES); do git submodule deinit -f $${mod}; done

init_submodules:
	mkdir -p "${REPOS}"
	cd "${REPOS}"; for mod in $(SUBMODULES); do git submodule add https://github.com/SUNET/$${mod}.git; done

real_clean: clean init_submodules

prebuild:
	cd prebuild && make docker

build: build_prep prebuild
	git submodule status > build/submodules.txt
	cd build && make VERSION=$(VERSION) docker

webapp:
	cd webapp && make VERSION=$(VERSION) docker

worker:
	cd worker && make VERSION=$(VERSION) docker

falconapi:
	cd falconapi && make VERSION=$(VERSION) docker

satosa_scim:
	cd satosa_scim && make VERSION=$(VERSION) docker

dockers: build $(DOCKERS)

dockers_tagpush:
	cd webapp && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd worker && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd falconapi && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd satosa_scim && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush

.PHONY: prebuild build webapp worker falconapi satosa_scim
