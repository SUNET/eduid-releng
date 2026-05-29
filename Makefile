REPOS=		${CURDIR}/build/repos
include build-toolchain-versions.mk
include base-image-versions.mk
include runtime-image-versions.mk
TAGSUFFIX?=	testing
STAGINGTAG?=	staging
PRODTAG?=	production
MAINBRANCH=	origin/main
BRANCH?=	$(MAINBRANCH)
SUBMODULES=	eduid-backend eduid-html eduid-front eduid-managed-accounts
DOCKERS=	webapp worker satosa_scim fastapi admintools html vccs
DATETIME:=	$(shell date -u +%Y%m%dT%H%M%S)
VERSION?=	$(DATETIME)

all:
	$(info --- INFO: eduID release engineering ---)
	$(info ---)
	$(info --- INFO: The main targets of this Makefile are: )
	$(info ---)
	$(info ---         update_what_to_build: Update what code will be built to the upstream branch $(BRANCH) ---)
	$(info ---         dockers:              Build docker images $(DOCKERS) ---)
	$(info ---)

# Build toolchain version pins.
show-build-toolchain-versions:
	@echo "Build toolchain versions"
	@echo "  uv version: $(UV_VERSION)"
	@echo "  uv asset:   $(UV_RELEASE_ASSET)"
	@echo "  uv sha256:  $(UV_RELEASE_SHA256)"

check-build-toolchain-versions:
	bash ./scripts/update-build-toolchain-versions.sh check

update-build-toolchain-versions:
	bash ./scripts/update-build-toolchain-versions.sh update

# Shared base image version pins.
show-base-image-versions:
	@echo "Base image versions"
	@echo "  debian:     $(DEBIAN_VERSION)"

check-base-image-versions:
	bash ./scripts/update-base-image-versions.sh check

update-base-image-versions:
	bash ./scripts/update-base-image-versions.sh update

# Service-specific runtime image version pins.
show-runtime-image-versions:
	@echo "Runtime image versions"
	@echo "  vccs luna tag:     $(VCCS_LUNA_IMAGE_TAG)"
	@echo "  vccs luna digest:  $(VCCS_LUNA_IMAGE_DIGEST)"

check-runtime-image-versions:
	bash ./scripts/update-runtime-image-versions.sh check

update-runtime-image-versions:
	bash ./scripts/update-runtime-image-versions.sh update

build_prep:
	git submodule update --init
	git submodule update
	git submodule foreach "git show --summary"

update_what_to_build: build_prep
	git pull
	git submodule foreach "git checkout ${MAINBRANCH}"
	git submodule foreach "git fetch origin"
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git show --summary"
	for mod in $(SUBMODULES); do git commit -m "updated submodule $${mod} to branch ${BRANCH}" build/repos/$${mod} || true; done

deinit_submodules:
	cd ${REPOS} && for mod in $(SUBMODULES); do git submodule deinit -f $${mod}; done

init_submodules:
	mkdir -p "${REPOS}"
	cd "${REPOS}"; for mod in $(SUBMODULES); do git submodule add https://github.com/SUNET/$${mod}.git; done

clean:
	docker rmi eduid-prebuild -f

real_clean: clean init_submodules

prebuild:
	cd prebuild && make docker \
	  UV_VERSION="$(UV_VERSION)" \
	  UV_RELEASE_ASSET="$(UV_RELEASE_ASSET)" \
	  UV_RELEASE_SHA256="$(UV_RELEASE_SHA256)"

build: build_prep prebuild
	git submodule status > build/submodules.txt
	cd build && make VERSION=$(VERSION) docker

webapp:
	cd webapp && make VERSION=$(VERSION) docker

worker:
	cd worker && make VERSION=$(VERSION) docker

satosa_scim:
	cd satosa_scim && make VERSION=$(VERSION) docker

fastapi:
	cd fastapi && make VERSION=$(VERSION) docker

admintools:
	cd admintools && make VERSION=$(VERSION) docker

html:
	cd html && make VERSION=$(VERSION) docker

vccs:
	cd vccs && make VERSION=$(VERSION) VCCS_LUNA_IMAGE_TAG=$(VCCS_LUNA_IMAGE_TAG) VCCS_LUNA_IMAGE_DIGEST=$(VCCS_LUNA_IMAGE_DIGEST) docker

dockers: build $(DOCKERS)

dockers_tagpush:
	cd webapp && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd worker && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd satosa_scim && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd fastapi && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd admintools && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd html && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	cd vccs && make VERSION=$(VERSION) TAGSUFFIX=$(TAGSUFFIX) docker_tagpush
	@echo ""
	@echo "--- INFO: eduID release engineering ---"
	@echo "---"
	@echo "---  Docker images for version $(VERSION) built and pushed)"
	@echo "---"
	@echo "---  Probable next step:"
	@echo "---"
	@echo "---    make VERSION=$(VERSION) REGISTRY=$(REGISTRY) staging_release"
	@echo "---"
	@echo "---  in the eduid-releng repository"
	@echo "---"

staging_release:
	cd webapp && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd worker && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd satosa_scim && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd fastapi && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd admintools && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd html && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush
	cd vccs && make VERSION=$(VERSION) SRCTAG=$(TAGSUFFIX) DSTTAG=$(STAGINGTAG) tag_copypush

production_release:
	cd webapp && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd worker && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd satosa_scim && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd fastapi && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd admintools && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd html && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush
	cd vccs && make VERSION=$(VERSION) SRCTAG=$(STAGINGTAG) DSTTAG=$(PRODTAG) tag_copypush

.PHONY: show-build-toolchain-versions check-build-toolchain-versions update-build-toolchain-versions show-base-image-versions check-base-image-versions update-base-image-versions show-runtime-image-versions check-runtime-image-versions update-runtime-image-versions prebuild build $(DOCKERS) staging_release production_release
