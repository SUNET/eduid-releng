# Make Targets Reference

## Purpose

List the main top-level targets exposed by the releng repository.

## Source Of Truth

- `Makefile`

## Build Selection

- `build_prep`: initialize and update submodules
- `update_what_to_build`: pull and check out the selected submodule branch

## Image Build

- `prebuild`: build `eduid-prebuild`
- `build`: export clean sources and build `eduid-build:$VERSION`
- `dockers`: build all runtime images

## Individual Images

- `webapp`
- `worker`
- `satosa_scim`
- `fastapi`
- `admintools`
- `html`
- `vccs`

## Promotion

- `dockers_tagpush`: publish testing-tagged images
- `staging_release`: promote testing tags to staging
- `production_release`: promote staging tags to production

## Version Review Helpers

- `show-base-image-versions`
- `check-base-image-versions`
- `update-base-image-versions`
- `show-runtime-image-versions`
- `check-runtime-image-versions`
- `update-runtime-image-versions`