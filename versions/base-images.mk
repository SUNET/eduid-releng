# Shared base image version pins.

# Debian base image identity used by releng-owned Debian-based Dockerfiles.
# Use the reviewed codename without pinning a specific image digest.
# Cadence notes for this pin:
# - Official Debian container images are republished by the Debian image maintainers
#   at least monthly (~30 days), and may be rebuilt sooner for a major or minor
#   Debian release or for a severe security issue.
#   Reference: https://github.com/debuerreotype/docker-debian-artifacts
# - Debian stable point releases are periodic rollups rather than continuous
#   updates; Debian's security FAQ describes them as happening every couple of
#   months via another stable revision.
#   References: https://www.debian.org/releases/stable/
#               https://www.debian.org/security/faq
# - Debian security advisories do not follow a fixed calendar. Debian publishes
#   fixes when they are ready, and notes that coordinated advisories are often
#   released the same day a vulnerability becomes public.
#   References: https://www.debian.org/security/
#               https://www.debian.org/security/faq
# Operational consequence: this image can lag the latest Debian security archive
# between container-image republishes even when the codename remains unchanged.
#
# Coupling: the vccs image runs the eduid-build venv (built on this Debian release)
# on top of the Luna base image. The Debian release in VCCS_LUNA_IMAGE_TAG
# (versions/runtime-images.mk) must match DEBIAN_VERSION, otherwise the venv's
# Python minor version and native libraries will not match the runtime interpreter.
DEBIAN_VERSION := trixie