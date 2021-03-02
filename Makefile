REPOS=		${CURDIR}/repos
SOURCES=	${CURDIR}/sources
WHEELS=		${CURDIR}/wheels
INDEX=		$(WHEELS)/simple
VENV=		"${HOME}/.virtualenvs/eduid-releng"
BRANCH=		ft-piptools_requirements
LOCAL_SOURCES=	"${HOME}/work/SUNET"
SUBMODULES=	eduid-am eduid-common eduid-lookup-mobile eduid_msg eduid-userdb eduid-webapp

update:
	git submodule update --init

clean:
	rm -rf sources; rsync -a repos/ sources
	rm -rf wheels
	mkdir wheels
	git submodule update
	git submodule foreach 'git reset --hard'
	git submodule foreach 'git fetch local'
	git submodule foreach "git checkout local/${BRANCH}"
	#git submodule foreach "git pull local ${BRANCH}"

deinit_submodules:
	cd ${REPOS} && for mod in $(SUBMODULES); do git submodule deinit -f $${mod}; done

init_submodules:
	mkdir -p "${REPOS}"
	cd "${REPOS}"; for mod in $(SUBMODULES); do git submodule add https://github.com/SUNET/$${mod}.git; done

add_local_sources: update
	git submodule foreach 'git remote remove local'
	cd "${REPOS}" && git submodule foreach 'git remote add -f local $(LOCAL_SOURCES)/$$displaypath'

real_clean: clean init_submodules add_local_sources

build: update clean
	VENV=$(VENV) SOURCES=$(SOURCES) ./build.sh

wheels: build
	cp -ia sources/*/dist/*whl $(WHEELS)
	$(VENV)/bin/piprepo build $(WHEELS)

install:
	$(VENV)/bin/pip install --extra-index-url "file://$(INDEX)" eduid-webapp

	echo "eduID packages installed:"
	echo ""
	pip freeze | grep ^eduid

all: build
