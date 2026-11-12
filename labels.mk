# Shared by the image Makefiles (include ../labels.mk).
#
# LABEL_ARGS holds docker build --label arguments recording which source commits
# an image is built from. tools/whats-deployed reads them back with
# `docker image inspect`.
#
# The runtime images copy their sources from the eduid-build:$(VERSION) image, so
# the commits are read from that image's /build/submodules.txt (written by
# `make build` from `git submodule status`), not from the current checkout.
# That keeps the labels correct when a single image is rebuilt after the
# submodules have moved. If eduid-build:$(VERSION) does not exist, or a
# submodule was not initialised when it was built, that label is omitted.

BUILD_IMAGE := eduid-build:$(VERSION)

# "eduid-backend=<sha> eduid-front=<sha> ..." from the build image
BUILD_REVS := $(shell test -n '$(VERSION)' && \
	docker run --rm --entrypoint cat $(BUILD_IMAGE) /build/submodules.txt 2>/dev/null \
	| awk '!/^-/ { sub(/^[ +U]/, ""); n = $$2; sub(/^build\/repos\//, "", n); print n "=" $$1 }')

LABEL_REPOS := eduid-backend eduid-front eduid-html eduid-managed-accounts

# $(call revision,eduid-backend)
revision = $(patsubst $(1)=%,%,$(filter $(1)=%,$(BUILD_REVS)))

# $(call label_arg,eduid-backend) -> --label "se.sunet.eduid.backend-rev=<sha>"
label_arg = $(if $(call revision,$(1)),--label "se.sunet.eduid.$(patsubst eduid-%,%,$(1))-rev=$(call revision,$(1))")

LABEL_ARGS = $(foreach m,$(LABEL_REPOS),$(call label_arg,$(m))) \
	--label "se.sunet.eduid.version=$(VERSION)"
