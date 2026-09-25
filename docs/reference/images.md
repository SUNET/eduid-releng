# Runtime Images Reference

## Purpose

Provide a quick lookup table for the runtime images assembled by this repository.

## Source Of Truth

- `Makefile`
- `images/*/Dockerfile`
- `images/*/Makefile`

| Image | Base | Main content | Notes |
| --- | --- | --- | --- |
| `runtime_common` | `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` | shared OS packages, `eduid` user, runtime directories | releng-owned parent for Debian-based runtime images |
| `webapp` | `eduid-runtime-common:$VERSION` | backend source + `/opt/eduid/webapp` | shared Python build path |
| `worker` | `eduid-runtime-common:$VERSION` | backend source + `/opt/eduid/worker` | Celery worker runtime |
| `fastapi` | `eduid-runtime-common:$VERSION` | backend source + `/opt/eduid/fastapi` | HTTP health check |
| `admintools` | `eduid-runtime-common:$VERSION` | backend source + `/opt/eduid/admintools` | administrative command surface |
| `satosa_scim` | `eduid-runtime-common:$VERSION` | backend source + `/opt/eduid/satosa_scim` | overlay patch step |
| `html` | `eduid-runtime-common:$VERSION` | nginx/static assets + frontend bundles | no Python venv |
| `vccs` | `${VCCS_LUNA_IMAGE_REF}` | backend source + runtime-built `/opt/eduid/fastapi` | Luna-backed exception path |