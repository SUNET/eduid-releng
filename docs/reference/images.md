# Runtime Images Reference

## Purpose

Provide a quick lookup table for the runtime images assembled by this repository.

## Source Of Truth

- `Makefile`
- `images/*/Dockerfile`
- `images/*/Makefile`

| Image | Base | Main content | Notes |
| --- | --- | --- | --- |
| `webapp` | `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` | backend source + `/opt/eduid/webapp` | shared Python build path |
| `worker` | `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` | backend source + `/opt/eduid/worker` | Celery worker runtime |
| `fastapi` | `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` | backend source + `/opt/eduid/fastapi` | HTTP health check |
| `admintools` | `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` | backend source + `/opt/eduid/admintools` | administrative command surface |
| `satosa_scim` | `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` | backend source + `/opt/eduid/satosa_scim` | overlay patch step |
| `html` | `debian:${DEBIAN_VERSION}@${DEBIAN_DIGEST}` | nginx/static assets + frontend bundles | no Python venv |
| `vccs` | `${VCCS_LUNA_IMAGE_REF}` | backend source + runtime-built `/opt/eduid/fastapi` | Luna-backed exception path |