# Shared base image version pins.

# Debian base image identity used by releng-owned Debian-based Dockerfiles.
# Keep the reviewed codename for operator readability and the digest for immutability.
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
# Operational consequence: this digest can lag the latest Debian security archive
# between container-image republishes even when the codename remains unchanged.
DEBIAN_VERSION := trixie
DEBIAN_DIGEST := sha256:4ae67669760b807c19f23902a3fd7c121a6a70cf2ae709035674b23e712e4d62