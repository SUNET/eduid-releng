REPOS=		${CURDIR}/repos
SOURCES=	${CURDIR}/sources
WHEELS=		${CURDIR}/wheels
INDEX=		$(WHEELS)/simple
VENV=		"${HOME}/.virtualenvs/eduid-releng"
BRANCH=		ft-piptools_requirements
LOCAL_SOURCES=	"${HOME}/work/SUNET"
SUBMODULES=	eduid-am eduid-common eduid-graphdb eduid-lookup-mobile eduid_msg eduid-userdb eduid-queue eduid-scimapi eduid-webapp

update:
	git submodule update --init
	git submodule update
	git submodule foreach 'git reset --hard'
	git submodule foreach 'git checkout master || git checkout main'
	git submodule foreach 'git fetch local'
	git submodule foreach "git checkout ${BRANCH}"
	git submodule foreach "git pull local ${BRANCH}"
	git submodule foreach "git show --summary"
	git submodule foreach "ls -l"
	rm -rf sources; rsync -a repos/ sources

clean:
	rm -rf wheels
	mkdir wheels

deinit_submodules:
	cd ${REPOS} && for mod in $(SUBMODULES); do git submodule deinit -f $${mod}; done

init_submodules:
	mkdir -p "${REPOS}"
	cd "${REPOS}"; for mod in $(SUBMODULES); do git submodule add https://github.com/SUNET/$${mod}.git; done
	git submodule foreach 'git remote remove local || true'
	cd "${REPOS}" && git submodule foreach 'git remote add -f local $(LOCAL_SOURCES)/$$displaypath'

venv:
	python3 -mvenv $(VENV)
	$(VENV)/bin/pip install wheel pip-tools piprepo
	$(VENV)/bin/pip install --extra-index https://pypi.sunet.se/simple pysmscom vccs-client


real_clean: clean init_submodules

build: clean update
	VENV=$(VENV) SOURCES=$(SOURCES) ./build.sh

wheels: build
	cp -ia sources/*/dist/*whl $(WHEELS)
	$(VENV)/bin/piprepo build $(WHEELS)

install: wheels
	$(VENV)/bin/pip install --extra-index-url "file://$(INDEX)" eduid-webapp

	echo "eduID packages installed:"
	echo ""
	pip freeze | grep ^eduid

all: venv install
