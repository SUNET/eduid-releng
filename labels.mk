# Shared by the image Makefiles (include ../labels.mk).
#
# LABEL_ARGS holds docker build --label arguments recording which source commits
# an image is built from. tools/whats-deployed reads them back with
# `docker image inspect`. The SHAs are the checked-out HEADs of the submodules,
# i.e. what build/Makefile exports with `git archive HEAD`. An uninitialised
# submodule gets no label.

LABELS_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
LABEL_REPOS := eduid-backend eduid-front eduid-html eduid-managed-accounts

# $(call submodule_sha,eduid-backend)
submodule_sha = $(shell git -C $(LABELS_ROOT) submodule status build/repos/$(1) 2>/dev/null | awk '!/^-/ { sub(/^[ +U]/, ""); print $$1 }')

# $(call label_arg,eduid-backend) -> --label "se.sunet.eduid.backend-rev=<sha>"
label_arg = $(if $(call submodule_sha,$(1)),--label "se.sunet.eduid.$(patsubst eduid-%,%,$(1))-rev=$(call submodule_sha,$(1))")

LABEL_ARGS = $(foreach m,$(LABEL_REPOS),$(call label_arg,$(m))) \
	--label "se.sunet.eduid.releng-rev=$(shell git -C $(LABELS_ROOT) rev-parse HEAD 2>/dev/null)" \
	--label "se.sunet.eduid.version=$(VERSION)"
