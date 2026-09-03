# Using dev-extra-modules.txt

## Purpose

`dev-extra-modules.txt` is a development-only escape hatch for adding Python packages to a running eduID container when the mounted backend source tree needs dependencies that are not already present in the image virtualenv.

This is useful when a developer is testing newer backend code against an older locally built image and the new code imports a package that was not part of the image build.

The releng startup scripts look for the file at:

```text
/opt/eduid/sources/eduid/dev-extra-modules.txt
```

If the file exists, the service installs the listed packages with `pip install -r ...` before starting.

## Where It Is Used

The following startup scripts currently support `dev-extra-modules.txt`:

- `images/webapp/start-webapp.sh`
- `images/fastapi/start-fastapi.sh`
- `images/vccs/start-fastapi.sh`
- `images/worker/start-worker.sh`

The file is expected to come from the mounted developer source tree referenced by `extra_sources_dir`, which defaults to `/opt/eduid/sources`.

## When To Use It

Use `dev-extra-modules.txt` when all of the following are true:

- you are developing against mounted local sources
- the code you mounted needs a new third-party Python dependency
- you do not want to rebuild the dev image immediately

This is a convenience mechanism for development. It is not the normal dependency-management path for release builds.

## How It Works

1. Mount a backend source tree into the container at `/opt/eduid/sources` or set `extra_sources_dir` to the mounted source location.
2. Create or update `eduid/dev-extra-modules.txt` inside that mounted source tree.
3. Add one requirement per line using normal `pip install -r` syntax.
4. Start the container normally.
5. The startup script installs the extra packages into the service virtualenv before starting the process.

## File Format

`dev-extra-modules.txt` uses standard pip requirements-file syntax.

Simple package names:

```text
apscheduler
redis
```

Pinned versions:

```text
apscheduler==3.10.4
redis==5.0.7
```

Version ranges:

```text
apscheduler>=3.10,<4
```

## Example: job_runner and apscheduler

One reported use case was developing `job_runner` code that started depending on `apscheduler` before the normal image had been rebuilt with that dependency.

In that case, the developer could place this in the mounted backend source tree:

```text
# /opt/eduid/sources/eduid/dev-extra-modules.txt
apscheduler
```

When the `worker` container starts, `images/worker/start-worker.sh` will install `apscheduler` into `/opt/eduid/worker` before launching the worker process.

That lets the developer test the new code path without first rebuilding the shared `eduid-build` image and then the runtime image.

## Example: multiple extra packages

```text
apscheduler
redis
structlog
```

If the mounted source code imports any of these packages and the base image does not already include them, the container startup path will add them to the virtualenv.

## Limitations

- It mutates the Python environment at container startup.
- It makes the running container differ from the original built image.
- It can slow down startup and fail at runtime if package resolution or download fails.
- It is not suitable as the primary mechanism for production or reproducible builds.

## Preferred Long-Term Path

If a dependency is truly required by the application, the preferred fix is to add it to the normal backend dependency inputs and rebuild the relevant images.

In this repository, that means:

1. update the tracked dependency inputs in `eduid-backend`
2. rebuild the shared build image so the service virtualenv is recreated
3. rebuild the affected runtime image

`dev-extra-modules.txt` should be treated as a development convenience, not the source of truth for service dependencies.