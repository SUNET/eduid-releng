# eduID Releng Documentation

## Purpose

This directory is the current documentation entry point for the eduID release-engineering repository.

It is organized by intent so operators and maintainers can find the current build and release contract quickly, while older analysis and draft material stays out of the main path.

## Status

- Primary audience: releng maintainers and operators

## Start Here

- Architecture: [architecture/overview.md](architecture/overview.md)
- Build and release operations: [operations/build.md](operations/build.md)
- Current contracts with upstream repos and runtime images: [contracts/backend-releng-contract.md](contracts/backend-releng-contract.md)
- Reproducibility and supply-chain policy: [policy/reproducibility.md](policy/reproducibility.md)
- Command and image lookup: [reference/make-targets.md](reference/make-targets.md)

## Layout

- `architecture/`: what this repo owns and how the build pipeline is structured
- `operations/`: operator-facing procedures for build, promotion, rollback, and troubleshooting
- `contracts/`: current interfaces between releng, upstream repos, and runtime images
- `policy/`: current rules, gaps, and review points around reproducibility and supply chain
- `reference/`: concise lookup material for targets, images, version files, and environment variables
- `adr/`: architecture decision records when repo-level decisions need durable rationale

## Source Of Truth

This documentation is secondary to the implementation. The current source of truth for releng behavior is the repository code and configuration, especially:

- `Makefile`
- `build/Makefile`
- `build/build-js.sh`
- `build/setup-venv.sh`
- `.forgejo/workflows/build-action.yaml`
- `images/*/Makefile`
- `images/*/Dockerfile`
- `images/*/start-*.sh`
- `versions/*.mk`