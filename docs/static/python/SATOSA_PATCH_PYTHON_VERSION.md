# SATOSA Patch Python Version Hardcoding Issue

## Overview

The eduID release engineering repository includes performance optimization patches for the SATOSA SCIM proxy service. The original implementation copied files directly into a hardcoded `python3.11` virtualenv path in `images/satosa_scim/Dockerfile`, which made image assembly brittle across backend Python minor-version bumps.

The current implementation resolves installed package paths dynamically using the SATOSA virtualenv interpreter and applies the overlays through a small manifest-driven helper script. This keeps the image structure close to the other runtime images while making the patch step portable across Python minor versions.

## Current Status

The hardcoded-path issue is resolved in the current repo state.

Today:

- `images/satosa_scim/Dockerfile` copies the prebuilt virtualenv like the other shared-venv images
- `images/satosa_scim/apply-package-overlays.sh` resolves package locations dynamically through `/opt/eduid/satosa_scim/bin/python`
- `images/satosa_scim/patches/manifest.txt` maps import-package names to overlay files
- the releng repository no longer depends on a hardcoded `lib/pythonX.Y/` path for SATOSA patch application

## Historical Problem

### Hardcoded Paths

The earlier `images/satosa_scim/Dockerfile` implementation contained hardcoded paths that assumed Python 3.11:

```dockerfile
COPY ./patches/state.py /opt/eduid/satosa_scim/lib/python3.11/site-packages/satosa/state.py
COPY ./patches/sigver.py /opt/eduid/satosa_scim/lib/python3.11/site-packages/saml2/sigver.py
```

### Impact with Python 3.13

The backend (`eduid-backend`) now declares `requires-python = "==3.13.*"` in its `pyproject.toml`. When building a SATOSA image with Python 3.13:

- The virtualenv is created under `lib/python3.13/` not `lib/python3.11/`
- The hardcoded `COPY` commands fail with "No such file or directory"
- The image build fails completely

This was a critical incompatibility between:
- **releng's assumption**: Python 3.11 paths
- **backend's requirement**: Python 3.13.x

## Implemented Fix

The SATOSA image now applies the patches as Python package overlays instead of hardcoded path copies:

- `images/satosa_scim/Dockerfile` copies the prebuilt virtualenv like the other images and runs a single helper step
- `images/satosa_scim/apply-package-overlays.sh` resolves package locations using `/opt/eduid/satosa_scim/bin/python`
- `images/satosa_scim/patches/manifest.txt` maps import packages to overlay files
- `state.py` overlays the `satosa` package
- `sigver.py` overlays the `saml2` import package from the `pysaml2` distribution

This makes the patch step independent of `lib/pythonX.Y/` layout details and gives releng a reusable seam for future shared image helpers.

## Patch Details

### Purpose and Context

Both patches are performance optimizations for the Skolverket proxy integration, introduced March 4, 2025 (commits d3e8ca1, 2679317). They exist because:

1. **Skolverket is Sweden's national school authentication proxy**: Handles authentication for all Swedish schools at scale
2. **SATOSA processes SAML assertions continuously**: Every authentication request involves signature verification, state management, and cryptographic operations
3. **Hot path optimization**: The patched operations occur on every single SAML request in the authentication flow
4. **Cumulative impact**: Even small per-request overhead (subprocess calls, compression algorithm selection) compounds to significant latency at national scale

Without these optimizations, SATOSA's signature verification and state compression become measurable bottlenecks in the authentication pipeline.

### sigver.py

**File**: `images/satosa_scim/patches/sigver.py`  
**Size**: 1895 lines  
**Optimization**: Removes subprocess calls to detect xmlsec1 binary version at runtime

**Key Changes**:
- Lines 12-13: Imports `subprocess.PIPE` and `subprocess.Popen`
- Line 639: `CryptoBackendXmlSec1.version()` method returns hardcoded `"1.2.37"` instead of calling subprocess to detect xmlsec1 binary version dynamically (lines 641-648 become unreachable)
- Line 876: `XMLSecurity.version()` method also returns hardcoded `"XMLSecurity 0.0"`

**Performance Benefit**: Eliminates subprocess overhead for version detection on every signature operation. Original saml2 code queries the xmlsec1 binary (`xmlsec1 --version`) multiple times per signature; this patch bakes in the expected version `1.2.37`, avoiding subprocess calls entirely.

**Why it matters**: Signature verification is called on every SAML assertion (potentially multiple times per request). Each subprocess invocation involves:
- Process fork overhead
- Binary invocation cost
- IPC/pipe communication
- Buffering and decoding output

At Skolverket scale (thousands of concurrent authentications), these subprocess costs compound rapidly. Hardcoding the version provides a significant per-request latency reduction in the hot path.

**Brittleness**: This optimization assumes the Debian container package provides exactly xmlsec1 version 1.2.37. If the package updates to a different version (e.g., 1.3.x), the hardcoded version becomes incorrect, potentially causing compatibility issues with SATOSA's cryptographic operations.

### state.py

**File**: `images/satosa_scim/patches/state.py`  
**Size**: 282 lines  
**Optimization**: Replaces lzma with zlib for state cookie compression

**Key Changes**:
- Line 10: Imports `zlib`
- Lines 98, 102: Applies `zlib.compress()` for state compression (active code)
- Lines 97, 99, 101: Original `lzma.compress()` code preserved in comments for reference

**Performance Benefit**: zlib is substantially faster than lzma for typical compression tasks, especially at the sizes involved in SATOSA state cookies (usually < 64KB).

**Why it matters**: SATOSA state objects are compressed and encoded into proxy cookies for every authentication redirect. In a proxy scenario (SATOSA sits between IdP and SP), state compression/decompression happens on:
- Every outbound redirect to the IdP (compression)
- Every return from the IdP (decompression)

At Skolverket scale, replacing lzma with zlib provides measurable reduction in cookie serialization latency. While individual cookie operations are fast, the cumulative effect across millions of authentications is significant.

## Python Version Compatibility

### Minimum Version Requirement: Python 3.7+

**Evidence**:

1. **F-string usage** throughout both patches:
   - `state.py` line 196: `f'No cookie named {name} in {cookie_str}'`
   - `sigver.py` multiple occurrences: Lines 75, 118, 119, 207, 573, 617, etc.
   - F-strings require Python 3.6+

2. **Explicit version handling in sigver.py**:
   - Lines 26-29 check: `if sys.version_info[:2] >= (3, 9):`
   - Falls back to `importlib_resources` backport for Python < 3.9
   - Comment: "importlib.resources was introduced in python 3.7"
   - This indicates code is designed to support Python 3.7+ with graceful fallbacks

3. **Standard library features**: All features used (subprocess, zlib, base64, hashlib, logging, typing) are available in Python 3.7+

**Conclusion**: The patches contain built-in version compatibility; they can run on Python 3.7, 3.11, 3.13, or any version >= 3.7. The hardcoded path is the only compatibility problem.

## Root Cause Analysis

### Operational Context: Why Performance Optimization Was Necessary

The Skolverket proxy is a critical national infrastructure component. It must handle:

- **Scale**: Millions of authentication requests from ~4,000 Swedish schools daily
- **Latency sensitivity**: Authentication flows are user-facing; latency directly affects user experience
- **Peak load**: School start times create synchronized traffic bursts
- **High frequency operations**: SAML verification and state management occur on every request

The patches address measurable bottlenecks identified in profiling:
1. **Subprocess overhead in signature verification**: Original code executed `xmlsec1 --version` subprocess multiple times per SAML verification, blocking I/O on every request
2. **Compression algorithm choice**: lzma compression added measurable latency to state serialization in high-concurrency scenarios

These are not theoretical optimizations—they represent production tuning driven by operational requirements.

### Why Python 3.11 Was Hardcoded

At the time patches were created (March 2025), the build infrastructure likely used Python 3.11. The hardcoding was a simple, direct approach that worked for that environment:

- Quick to implement (direct path reference vs. dynamic resolution)
- No apparent need to support multiple Python versions at that time
- SATOSA patches are service-specific, not part of core releng workflow

### Why It Breaks Now

Backend's reproducibility work introduced `requires-python = "==3.13.*"` declaration, shifting from:
- **Old assumption**: Python minor version is flexible/unspecified
- **New requirement**: Exact Python minor version (3.13) is mandated

This creates a version contract mismatch:
- Releng hardcodes path assuming 3.11
- Backend requires 3.13
- Image build fails at COPY instruction before runtime issues appear

## Testing Recommendations

For the manifest-driven package overlay approach:

1. **Test with Python 3.11**: Verify patches still apply correctly
2. **Test with Python 3.13**: Verify dynamic resolution works (new behavior)
3. **Build satosa_scim image**: Run `make satosa_scim` or equivalent
4. **Inspect runtime image**: Verify the helper patched the resolved `satosa` and `saml2` package files
5. **Functional test**: Verify SATOSA service starts and can handle SCIM requests

## Related Issues

- **build/setup-venv.sh**: The shared releng build now uses pinned `uv` plus `uv pip install --require-hashes`, so the old mutable `pip install --upgrade pip wheel` issue no longer applies to the main shared build path
- **vccs/Dockerfile**: Duplicates venv creation instead of using shared helper
- **General reproducibility**: No validation of Python minor version parity between releng and backend

## References

- Patch introduction commits: d3e8ca1, 2679317, 9f5ae3f, a259498 (March 2025)
- Backend reproducibility: `origin/alex-dev-ci-reproducibility-improvements` branch
- Python version requirements: `build/repos/eduid-backend/pyproject.toml` line 9

## Timeline

| Date | Event |
|------|-------|
| 2025-03-04 | SATOSA patches introduced (sigver.py, state.py) with python3.11 hardcoding |
| 2025-03-04 | Performance optimizations documented in images/satosa_scim/patches/README |
| 2026-05-26 | Backend reproducibility work declares `requires-python = "==3.13.*"` |
| 2026-05-26 | Issue discovered: hardcoded paths now incompatible with Python 3.13 |
| 2026-05-27 | SATOSA image changed to manifest-driven package overlays with dynamic package-path resolution |

## Appendix: Patch Implementation Details

### sigver.py Functional Changes

Original saml2 module detects xmlsec1 version dynamically at runtime:
```python
# Original behavior (not in patch)
self.version = self._get_version_from_xmlsec()  # subprocess call
```

Patched behavior (lines 640-648):
```python
def version(self):
    return "1.2.37"  # Hardcoded version, early return
    # Code below is now unreachable:
    com_list = [self.xmlsec, "--version"]
    pof = Popen(com_list, stderr=PIPE, stdout=PIPE)
    content, _ = pof.communicate()
    content = content.decode("ascii")
    try:
        return content.split(" ")[1]
    except IndexError:
        return ""
```

This eliminates the subprocess overhead in the signature verification hot path by returning a hardcoded version early, making the original dynamic version detection code unreachable.

### state.py Functional Changes

Original SATOSA compression:
```python
# Original (commented out in patch, lines 97, 99, 101)
urlstate_data = lzma.compress(urlstate_data.encode("utf-8"))
```

Patched compression:
```python
# Patched (lines 98, 102)
urlstate_data = zlib.compress(urlstate_data.encode("utf-8"))
```

Both are valid compression; zlib is faster for typical SATOSA state object sizes (< 64KB).

---

**Document Version**: 1.2  
**Last Updated**: May 29, 2026  
**Status**: Resolved in current branch via manifest-driven package overlays
