# Shared Make Logic Layout Proposal

## Purpose

This note expands the structural proposal to move shared Make logic out of the repository root and service directories into one dedicated directory.

The goal is to separate three concerns that are currently mixed together:

1. service metadata
2. single-service Docker mechanics
3. multi-service release orchestration

This is a structure and maintainability proposal for the releng repository itself. It does not propose changing upstream repositories under `build/repos/`, and it does not propose modifying generated exports under `build/sources/`.

## Problem Statement

The current repository spreads Make logic across several layers at once:

- the root `Makefile` contains user-facing entry points and repeated release orchestration
- `build/Makefile` contains shared build-stage logic and repeated service lists
- each service directory contains its own small Makefile with nearly identical Docker rules

That produces two problems.

### 1. Data and behavior are coupled

Service facts such as image names, paths, and exceptions are embedded directly in executable Make rules rather than being declared once in a shared catalog.

### 2. The same logic is repeated at different levels

The repo repeats:

- service inventories
- image names
- `docker` target bodies
- tag and push flows
- promotion orchestration

This makes the repo harder to change safely. A change that should affect one concept often requires edits in several unrelated files.

## Structural Goal

Create one explicit home for reusable Make-based releng logic.

That home should contain:

- a service catalog
- reusable single-service rules
- reusable multi-service orchestration rules

This would let the top-level `Makefile` become a thin entry point, while per-service Makefiles become thin declarations rather than handwritten copies of the same behavior.

## Shared Orchestration Directory

This proposal assumes one dedicated directory named `orchestration/` for shared coordination logic.

That name fits the role of this repository: coordinating service metadata, per-service image rules, and multi-service release flow.

In the proposed structure, `orchestration/` sits beside other role-oriented directories such as `build/`, `images/`, `versions/`, `scripts/`, and `docs/`.

## Proposed Directory Layout

```text
/
  Makefile
	orchestration/
    services.mk
		service-image.mk
    release.mk
```

This layout means:

- the root `Makefile` stays as the user-facing entry point
- `orchestration/services.mk` becomes the shared data layer
- `orchestration/service-image.mk` becomes the shared single-service rule layer
- `orchestration/release.mk` becomes the shared multi-service orchestration layer

## A. `orchestration/services.mk`: Service Catalog And Shared Metadata

### Purpose

`services.mk` should be the declarative source of truth for service inventory and service-specific metadata.

Its job is to describe what exists and what varies per service, without embedding operational workflows.

### What Should Live Here

Typical contents:

- the canonical service list
- the directory for each service
- the local Docker image tag name for each service
- the remote registry image reference for each service
- the service type or kind
- service-specific build arguments
- service-specific flags that indicate exceptional behavior

### Why This Helps

Today the repo repeats the service inventory and image identity in multiple places. `services.mk` turns that into one catalog that can be reused by both the root orchestration and individual service builds.

That means:

- adding a new service starts with one metadata change
- the root `Makefile` no longer needs hardcoded parallel lists
- shared Make rules can derive behavior from declared service properties

### Example Shape

```make
SERVICES := webapp worker fastapi satosa_scim admintools html vccs

SERVICE_DIR_webapp := webapp
SERVICE_DIR_worker := worker
SERVICE_DIR_fastapi := fastapi
SERVICE_DIR_satosa_scim := satosa_scim
SERVICE_DIR_admintools := admintools
SERVICE_DIR_html := html
SERVICE_DIR_vccs := vccs

LOCAL_IMAGE_webapp := eduid-webapp
LOCAL_IMAGE_worker := eduid-worker
LOCAL_IMAGE_fastapi := eduid-fastapi
LOCAL_IMAGE_satosa_scim := eduid-satosa_scim
LOCAL_IMAGE_admintools := eduid-admintools
LOCAL_IMAGE_html := eduid-html
LOCAL_IMAGE_vccs := eduid-vccs

REMOTE_IMAGE_webapp := $(REGISTRY)/eduid/webapp
REMOTE_IMAGE_worker := $(REGISTRY)/eduid/worker
REMOTE_IMAGE_fastapi := $(REGISTRY)/eduid/fastapi
REMOTE_IMAGE_satosa_scim := $(REGISTRY)/eduid/satosa_scim
REMOTE_IMAGE_admintools := $(REGISTRY)/eduid/admintools
REMOTE_IMAGE_html := $(REGISTRY)/eduid/html
REMOTE_IMAGE_vccs := $(REGISTRY)/eduid/vccs

SERVICE_KIND_webapp := python
SERVICE_KIND_worker := python
SERVICE_KIND_fastapi := python
SERVICE_KIND_satosa_scim := python
SERVICE_KIND_admintools := python-admin
SERVICE_KIND_html := static
SERVICE_KIND_vccs := python-exception
```

### Suggested Additional Metadata

The first version should stay simple, but these fields are useful if they already exist in behavior today:

- whether the service uses shared Debian base pins
- whether the service tags `latest`
- whether the service participates in common promotion targets
- whether the service uses the shared build image
- whether the service is expected to remain an exception

Example:

```make
USES_SHARED_DEBIAN_BASE_webapp := 1
USES_SHARED_DEBIAN_BASE_vccs := 0

TAGS_LATEST_webapp := 1
TAGS_LATEST_worker := 1
TAGS_LATEST_vccs := 1

IS_SPECIAL_CASE_satosa_scim := 1
IS_SPECIAL_CASE_html := 1
IS_SPECIAL_CASE_vccs := 1
```

### What Should Not Live Here

Avoid putting these in `services.mk`:

- full target bodies
- `for` loops
- shell pipelines
- push and promotion workflows
- path-dependent command logic

If those live here, the file stops being a catalog and becomes another hard-to-reason-about execution layer.

### Practical Rule

If a line answers the question “what is true about this service?”, it belongs here.

If it answers “what should Make do?”, it probably belongs in one of the other include files.

## B. `orchestration/service-image.mk`: Common Per-Service Image Rules

### Purpose

`service-image.mk` should hold the shared implementation of the repeated targets currently copied across service directories.

In the current repo, most service Makefiles repeat the same three behaviors:

- build the local Docker image
- tag and push a versioned remote image
- pull, retag, and push an image for promotion

This file should define those behaviors once.

### What Should Live Here

This include should implement generic rules such as:

- `docker`
- `docker_tagpush`
- `tag_copypush`

It should assume that the calling Makefile has already declared or imported the variables it needs.

Typical inputs:

- `SERVICE`
- `SERVICE_DIR`
- `LOCAL_IMAGE`
- `REMOTE_IMAGE`
- `VERSION`
- `EXTRA_DOCKER_BUILD_ARGS`

### Why This Helps

This removes the near-identical Makefile bodies from:

- `images/webapp/Makefile`
- `images/worker/Makefile`
- `images/fastapi/Makefile`
- `images/satosa_scim/Makefile`
- `images/admintools/Makefile`
- `images/html/Makefile`
- `images/vccs/Makefile`

The service Makefiles then become thin wrappers that declare service identity and include the shared rule file.

### Example Shape

```make
docker:
	test -n '$(VERSION)' || exit 1
	docker build $(EXTRA_DOCKER_BUILD_ARGS) \
	  --build-arg "VERSION=$(VERSION)" \
	  --tag "$(LOCAL_IMAGE):$(VERSION)" \
	  .
	if [ "$(TAGS_LATEST)" = "1" ]; then docker tag "$(LOCAL_IMAGE):$(VERSION)" "$(LOCAL_IMAGE):latest"; fi

docker_tagpush:
	test -n '$(VERSION)' || exit 1
	test -n '$(TAGSUFFIX)' || exit 1
	docker tag "$(LOCAL_IMAGE):$(VERSION)" "$(REMOTE_IMAGE):$(VERSION)-$(TAGSUFFIX)"
	docker push "$(REMOTE_IMAGE):$(VERSION)-$(TAGSUFFIX)"

tag_copypush:
	test -n '$(VERSION)' || exit 1
	test -n '$(SRCTAG)' || exit 1
	test -n '$(DSTTAG)' || exit 1
	docker pull "$(REMOTE_IMAGE):$(VERSION)-$(SRCTAG)"
	docker tag "$(REMOTE_IMAGE):$(VERSION)-$(SRCTAG)" "$(REMOTE_IMAGE):$(VERSION)-$(DSTTAG)"
	docker push "$(REMOTE_IMAGE):$(VERSION)-$(DSTTAG)"
```

### Expected Calling Pattern

Each service directory would keep a small Makefile like this:

```make
include ../versions/base-images.mk
include ../orchestration/services.mk

SERVICE := webapp
LOCAL_IMAGE := $(LOCAL_IMAGE_$(SERVICE))
REMOTE_IMAGE := $(REMOTE_IMAGE_$(SERVICE))
TAGS_LATEST := 1
EXTRA_DOCKER_BUILD_ARGS := --build-arg "DEBIAN_VERSION=$(DEBIAN_VERSION)" --build-arg "DEBIAN_DIGEST=$(DEBIAN_DIGEST)"

include ../orchestration/service-image.mk
```

### Required Override Hooks

This include should support exceptions explicitly rather than forcing services to copy the whole rule set again.

Useful hooks include:

- `EXTRA_DOCKER_BUILD_ARGS`
- `BUILD_CONTEXT`
- `TAGS_LATEST`
- `PRE_DOCKER_BUILD`
- `POST_DOCKER_BUILD`
- `LOCAL_IMAGE`
- `REMOTE_IMAGE`

That lets a service change one behavior without forking the whole Make implementation.

### Important Design Constraint

Do not try to make every service identical.

The point is not to erase real differences. The point is to centralize the repeated contract and leave narrow hooks for actual exceptions such as:

- `vccs` using different build arguments and base image inputs
- `html` having a different runtime payload
- `satosa_scim` carrying overlay steps and service-specific details

## C. `orchestration/release.mk`: Root-Level Multi-Service Orchestration Rules

### Purpose

`release.mk` should contain the root-level orchestration that operates across multiple services.

This is different from `docker-service.mk`.

- `service-image.mk` defines how one service is built or promoted
- `release.mk` defines how the repository runs those operations across all relevant services

### What Should Live Here

Typical contents:

- `dockers`
- `dockers_tagpush`
- `staging_release`
- `production_release`
- optional scoped service-selection logic

### Why This Helps

The top-level `Makefile` currently hardcodes the same service list into several orchestration targets. `release.mk` allows those loops to be defined once and derived from the shared catalog in `services.mk`.

That means:

- there is one place to control cross-service behavior
- adding or removing a service affects fewer files
- dry-run validation becomes easier to compare and reason about

### Example Shape

```make
RELEASE_SERVICES ?= $(SERVICES)

dockers: build
	@for service in $(RELEASE_SERVICES); do \
	  $(MAKE) -C $(SERVICE_DIR_$$service) VERSION="$(VERSION)" docker || exit 1; \
	done

dockers_tagpush:
	@for service in $(RELEASE_SERVICES); do \
	  $(MAKE) -C $(SERVICE_DIR_$$service) VERSION="$(VERSION)" TAGSUFFIX="$(TAGSUFFIX)" docker_tagpush || exit 1; \
	done

staging_release:
	@for service in $(RELEASE_SERVICES); do \
	  $(MAKE) -C $(SERVICE_DIR_$$service) VERSION="$(VERSION)" SRCTAG="$(TAGSUFFIX)" DSTTAG="$(STAGINGTAG)" tag_copypush || exit 1; \
	done

production_release:
	@for service in $(RELEASE_SERVICES); do \
	  $(MAKE) -C $(SERVICE_DIR_$$service) VERSION="$(VERSION)" SRCTAG="$(STAGINGTAG)" DSTTAG="$(PRODTAG)" tag_copypush || exit 1; \
	done
```

### Useful Extensions

Once the orchestration is centralized, the repo can add capabilities that are hard to express cleanly in the current layout:

- `RELEASE_SERVICES="webapp worker" make dockers`
- grouped targets for subsets of services
- service metadata inspection targets
- optional future parallel execution

Example:

```make
print-services:
	@printf '%s\n' $(SERVICES)

print-release-services:
	@printf '%s\n' $(RELEASE_SERVICES)
```

### What Should Stay In The Root `Makefile`

The root file should remain the user-facing entry point and contain only high-level repository contract items such as:

- top-level includes
- global defaults
- truly root-specific targets like `build_prep`
- the top-level help or `all` target

It should stop being the place where every service is manually enumerated for each release stage.

## How The Three Files Work Together

The intended dependency flow is:

```text
orchestration/services.mk
  -> used by per-service Makefiles
	-> used by orchestration/release.mk
  -> optionally used by build/Makefile

orchestration/service-image.mk
  -> included by each service Makefile

orchestration/release.mk
  -> included by the root Makefile
  -> dispatches into per-service Makefiles
```

This keeps responsibilities separated.

### `services.mk`

Declares facts.

### `service-image.mk`

Implements one-service behavior.

### `release.mk`

Implements all-service orchestration.

## Example End State

### Root `Makefile`

```make
include versions/build-toolchain.mk
include versions/base-images.mk
include versions/runtime-images.mk
include orchestration/services.mk
include orchestration/release.mk

all:
	$(info --- INFO: eduID release engineering ---)
```

### Service Makefile Example

```make
include ../versions/base-images.mk
include ../orchestration/services.mk

SERVICE := webapp
LOCAL_IMAGE := $(LOCAL_IMAGE_$(SERVICE))
REMOTE_IMAGE := $(REMOTE_IMAGE_$(SERVICE))
TAGS_LATEST := 1
EXTRA_DOCKER_BUILD_ARGS := --build-arg "DEBIAN_VERSION=$(DEBIAN_VERSION)" --build-arg "DEBIAN_DIGEST=$(DEBIAN_DIGEST)"

include ../orchestration/service-image.mk
```

This is materially easier to maintain than repeating the same target implementations in each service directory.

## Recommended Migration Order

The implementation order matters.

### Phase 1

Add `orchestration/services.mk` and move the service inventory there.

### Phase 2

Add `orchestration/release.mk` and move root-level orchestration loops there.

### Phase 3

Add `orchestration/service-image.mk` and convert service Makefiles one by one.

### Phase 4

Only after the logic is centralized, consider moving service directories into a grouped location such as `images/`.

This order minimizes path churn and keeps validation simple.

## Validation Strategy

When implementing this layout, use narrow Make dry runs before attempting real builds.

Recommended checks:

1. `make -n dockers`
2. `make -n dockers_tagpush VERSION=test`
3. `make -n staging_release VERSION=test`
4. `make -n production_release VERSION=test`
5. `make -n webapp VERSION=test`
6. `make -n vccs VERSION=test`

These checks are sufficient to catch most include-path, variable-expansion, and orchestration regressions introduced by the reorganization.

## Recommendation

The repository should create one dedicated directory for shared coordination logic named `orchestration/`.

Within that directory, responsibilities should be split as follows:

- `orchestration/services.mk`: declarative service catalog and shared metadata
- `orchestration/service-image.mk`: reusable per-service image rules
- `orchestration/release.mk`: reusable multi-service release orchestration

This gives the repository a clearer structure, reduces duplication, and creates a safer path to later changes such as moving runtime image directories under a grouped `images/` hierarchy.