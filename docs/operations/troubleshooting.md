# Troubleshooting

## Purpose

Provide a short operator-oriented checklist for common releng failures.

## Source Of Truth

- `build/build-js.sh`
- `build/setup-venv.sh`
- `images/*/Dockerfile`
- `.forgejo/workflows/build-action.yaml`

## Common Failure Areas

### Frontend build fails immediately

Check:

- `package-lock.json` exists in the exported frontend source
- `npm ci --ignore-scripts --no-audit --no-fund` succeeds
- the expected build script still exists upstream

### Shared Python build fails

Check:

- `uv` is present in the prebuild image
- `python3` matches backend requirements closely enough
- the relevant requirements file exists under `build/sources/eduid-backend/requirements/`
- `uv pip install --require-hashes` is failing for a real dependency reason, not because of missing system packages

### VCCS build differs from other Python images

Check:

- the selected `VCCS_LUNA_IMAGE_TAG`
- whether `fastapi_requirements.txt` failed and the Dockerfile fell back to `main.txt`
- system package availability in the Luna-based image

### CI behavior differs from local behavior

Check:

- the Forgejo workflow still sets `DOCKER_BUILDKIT=0`
- registry login behavior
- Docker builder availability from `docker buildx ls`

## Fast Triage Commands

```bash
git status --short
make -n dockers
bash -n build/build-js.sh build/setup-venv.sh
git --no-pager diff
```