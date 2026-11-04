# ADR 0000: Use Debian Stable And Debian-Provided Python

- Status: Accepted
- Date: Original project baseline; exact decision date not recorded
- Recorded: 2026-10-07
- Type: Retrospective

## Context

Debian stable and Debian-provided Python have been project policies since the
beginning. This ADR records those original decisions; it does not introduce a
new baseline or attribute them to the later adoption of `uv`.

The release pipeline needs a consistent operating-system baseline and a trusted
source of Python interpreters across build and runtime environments.

## Decision

Use Debian stable as the project baseline for build and runtime images.
Exceptions, including externally supplied service bases, must be explicitly
reviewed and documented.

Use Python supplied and maintained by Debian packages for releng-managed Python
environments. Accept the Python version supplied by the selected Debian stable
release rather than independently pinning its minor version, downloading an
alternative interpreter, or overwriting Debian-managed Python files.

Python environment-management tools must use the Debian interpreter. Software
bundled in an external base image may have its own interpreter; that does not
change the interpreter policy for releng-managed environments.

## Consequences

Positive:

- operating-system and interpreter maintenance follow Debian's stable release
  and package-update process
- interpreter provenance is tied to the selected Debian release
- releng does not maintain a separate Python minor-version selection

Negative:

- application Python requirements must remain compatible with Debian's version
- adopting a new Debian stable release requires build and runtime validation
- external service bases require review for departures from the baseline

## Historical Evidence

The project maintainer confirms that Debian stable and Debian-provided Python
were project policies from the beginning. The earliest explicit implementation
evidence is commit `0b00947` (2021-03-03):

- `prebuild/Dockerfile` uses `FROM debian:stable` and installs Debian Python
  packages, including `libpython3-dev` and `python3-venv`, through apt
- `webapp/Dockerfile` and `worker/Dockerfile` use `FROM debian:stable` and install
  `python3-minimal` through apt

The preceding Dockerfile in commit `66e3998` (also 2021-03-03) uses the external
`docker.sunet.se/eduid/python3env` image. Its Dockerfile alone does not establish
that base image's operating-system or interpreter provenance.

The repository began on 2021-03-02. The history therefore supports this baseline
from the initial build implementation period, but does not establish the exact
original policy decision date.