REPOS=		${CURDIR}/build/repos
SOURCES=	${CURDIR}/sources
WHEELS=		${CURDIR}/wheels
INDEX=		$(WHEELS)/simple
VENV?=		"${HOME}/.virtualenvs/eduid-releng"
TAGSUFFIX?=	testing
STAGINGTAG?=	staging
PRODTAG?=	production
MAINBRANCH=	origin/main
BRANCH?=	$(MAINBRANCH)
SUBMODULES=	eduid-backend
DOCKERS=        webapp worker falconapi satosa_scim fastapi admintools
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
	git submodule update --remote
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"

update_what_to_build: build_prep
	git pull
	git submodule foreach "git checkout ${MAINBRANCH}"
	git submodule foreach "git fetch origin"
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"
	git commit -m "updated eduid-releng submodule to branch ${BRANCH}" build/repos/eduid-backend

deinit_submodules:
	cd ${REPOS} && for mod in $(SUBMODULES); do git submodule deinit -f $${mod}; done

init_submodules:
	mkdir -p "${REPOS}"
	cd "${REPOS}"; for mod in $(SUBMODULES); do git submodule add https://github.com/SUNET/$${mod}.git; done

clean:
	docker rmi eduid-prebuild -f

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

fastapi:
	cd fastapi && make VERSION=$(VERSION) docker

admintools:
	cd admintools && make VERSION=$(VERSION) docker

dockers: build $(DOCKERS)

dockers_tagpush:
	cd webapp && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd worker && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd falconapi && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd satosa_scim && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd fastapi && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd admintools && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	@echo ""
	@echo "--- INFO: eduID release engineering ---"
	@echo "---"
	@echo "---  Docker images for version $(VERSION) built and pushed)"
	@echo "---"
	@echo "---  Probable next step:"
	@echo "---"
	@echo "---    make VERSION=$(VERSION) staging_release"
	@echo "---"
	@echo "---  in the eduid-releng repository"
	@echo "---"

staging_release:
	cd webapp && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd worker && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd falconapi && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd satosa_scim && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd fastapi && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd admintools && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush

production_release:
	cd webapp && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd worker && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd falconapi && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd satosa_scim && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd fastapi && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd admintools && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush

.PHONY: prebuild build $(DOCKERS) staging_release production_release
