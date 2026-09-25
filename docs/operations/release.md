# Release Operations

## Purpose

Document the current release flow from build to published testing images.

## Source Of Truth

- `Makefile`
- `.forgejo/workflows/build-action.yaml`
- `images/*/Makefile`

## Current Model

This repository uses a promotion model rather than rebuilding for each environment.

The version string defaults to the current UTC timestamp from the root `Makefile`.

## Build And Publish Testing Images

```bash
make dockers
make VERSION=<version> dockers_tagpush
```

The active Forgejo workflow effectively runs:

```bash
make dockers dockers_tagpush REGISTRY=platform.sunet.se
```

with `DOCKER_BUILDKIT=0`.

## Published Image Names

The service Makefiles publish to:

- `platform.sunet.se/eduid/webapp`
- `platform.sunet.se/eduid/worker`
- `platform.sunet.se/eduid/fastapi`
- `platform.sunet.se/eduid/satosa_scim`
- `platform.sunet.se/eduid/admintools`
- `platform.sunet.se/eduid/html`
- `platform.sunet.se/eduid/vccs`

## Notes

- The active automation builds and pushes testing-tagged images.
- Staging and production are separate promotion steps.
- The current release flow is tag-based rather than digest-based.