# Frontend Releng Contract

## Purpose

Define the current interface between releng and the frontend repositories.

## Source Of Truth

- `build/build-js.sh`
- `build/Makefile`
- `images/html/Dockerfile`

## Repositories In Scope

- `eduid-front`
- `eduid-managed-accounts`
- `eduid-html`

## What Releng Expects

- committed `package-lock.json` files for the built frontend repos
- release-compatible build scripts in the exported source tree
- output directories that match the current copy logic
- `eduid-html` content that still integrates with the built frontend artifacts

## What Releng Does

For `eduid-front` and `eduid-managed-accounts`, releng:

1. exports the source tree into `build/sources/`
2. fails the build if `package-lock.json` is missing
3. runs `npm ci --ignore-scripts --no-audit --no-fund`
4. builds frontend artifacts
5. places built outputs under `/opt/eduid/`

Current build commands:

- `eduid-front`: `npm run build-staging` and `npm run build-production`
- `eduid-managed-accounts`: `npx vite build`

## Delivery Contract

The `html` runtime image is the integration point for:

- `eduid-html` static and nginx content
- `eduid-front` build output
- `eduid-managed-accounts` build output

## What Releng Does Not Guarantee

- frontend tests as part of the releng build path
- automatic adaptation to renamed scripts or moved output directories
- application-level routing or browser logic correctness