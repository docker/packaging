# Packaging Guidelines

Docker-maintained `.deb` and `.rpm` packages follow a consistent set of
guidelines. New packages are expected to meet the same bar.

## Build from source in the package path

The shipped binary must be compiled from source by the distro package recipe
itself. For Debian packages, that means the build happens through
`debian/rules` / `dh_auto_build`. For RPM packages, that means the build
happens through the spec `%build` section and the result is installed into
the buildroot from `%install`. The package build may stage source files and
helper scripts, but it must not install a compiled binary produced by a
separate target, image, CI artifact, or non-package build step. Binary
packages don't need to contain source in their payload; what matters is that
the package build *consumes source as an input* and produces the binary itself.

## Tie the package to its target distro environment

Because the binary is built inside the target distro image, the package is bound
to the correct toolchain, libc, system libraries, packaging flags, and any
distro-specific build assumptions. Copying in a binary produced elsewhere breaks
that link — the package would ship a binary that was not actually built for the
environment the package represents.

## The source revision is the source of truth

The input to a package build is the source revision, not a prebuilt CI artifact.
The contract is `source → distro package build environment → binary → package`,
never `prebuilt artifact → package`. The artifact boundary matters even when the
binary is produced from the same commit in the same release pipeline.

## Preserve honest provenance and SBOMs

The package provenance must describe the actual build chain for the package:
`source revision → distro package build environment → binary → package`.

Binary packages do not need to include source in their payload, and private
source can remain private. What matters is that the source revision or digest is
recorded as build material, and that the binary shipped in the package is
produced by the package build itself.

A package build that installs a prebuilt binary can only honestly attest to
`prebuilt binary → package`. Even if that binary was produced from the same
commit in another trusted CI job, the package attestation no longer covers the
full source-to-package chain, and the package SBOM is less useful for auditing
how the shipped binary was produced.

This follows the provenance model described by SLSA, where the attestation
records the materials and build steps used to produce the artifact:
https://slsa.dev/spec/v1.2/provenance
