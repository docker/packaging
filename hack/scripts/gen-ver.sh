#!/usr/bin/env bash

# Copyright 2022 Docker Packaging authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -x
# optional tag prefix to handle versions like:
# cmd/cli/v0.1.44 -> v0.1.44
# docker-v29.0.0 -> v29.0.0
: "${TAGPREFIX:=}"

srcdir="$1"
if [ -z "$srcdir" ]; then
  echo "usage: ./gen-ver <srcdir>" >&2
  exit 1
fi

tagregex="${TAGPREFIX}v[0-9]*"
version=$(git -C "${srcdir}" describe --match "$tagregex" --tags)
commit="$(git --git-dir "${srcdir}/.git" rev-parse HEAD)"
commitShort=${commit:0:7}

if [ -n "$TAGPREFIX" ]; then
  version="${version#$TAGPREFIX}"
fi

# rpm "Release:" field ($rpmRelease) is used to set the "_release" macro, which
# is an incremental number for builds of the same release (Version: / #rpmVersion).
#
# This field can be:
#
# - Version: 0   : Package was built, but no matching upstream release (e.g., can be used for "nightly" builds)
# - Version: 1   : Package was built for an upstream (pre)release version
# - Version: > 1 : Only to be used for packaging-only changes (new package built for a version for which a package was already built/released)
#
# For details, see the Fedora packaging guide:
# https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/#_complex_versioning_with_a_reasonable_upstream
#
# Note that older versions of the rpm spec allowed more traditional information
# in this field, which is still allowed, but considered deprecated; see
# https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/#_complex_versioning_with_a_reasonable_upstream
#
# In our case, this means that all releases, except for "nightly" builds should
# use "Version: 1". Only in an exceptional case, where we need to publish a new
# package (build) for an existing release, "Version: 2" should be used; this script
# does not currently account for that situation.
#
# Assuming all tagged version of rpmRelease correspond with an upstream release,
# this means that versioning is as follows:
#
# Docker 22.06.0:         version=22.06.0, release=1
# Docker 22.06.0-alpha.1: version=22.06.0, release=1
# Docker 22.06.0-beta.1:  version=22.06.0, release=1
# Docker 22.06.0-rc.1:    version=22.06.0, release=1
# Docker 22.06.0-dev:     version=0.0.0~YYYYMMDDHHMMSS.gitHASH, release=0
rpmRelease=1

# if NIGHTLY_BUILD=1, or we have a "-dev" suffix or a commit not pointing to a
# tag, this is a nightly build, and we'll create a pseudo version based on
# commit-date and -sha.
if [[ "$NIGHTLY_BUILD" == "1" ]] || [[ "$version" == *-dev ]] || [[ -z "$(git -C "${srcdir}" tag --points-at HEAD --sort -version:refname)" ]]; then
  # based on golang's pseudo-version: https://groups.google.com/forum/#!topic/golang-dev/a5PqQuBljF4
  #
  # using a "pseudo-version" of the form v0.0.0-yyyymmddhhmmss-abcdefa,
  # where the time is the commit time in UTC and the final suffix is the prefix
  # of the commit hash. The time portion ensures that two pseudo-versions can
  # be compared to determine which happened later, the commit hash identifes
  # the underlying commit, and the v0.0.0- prefix identifies the pseudo-version
  # as a pre-release before version v0.0.0, so that the go command prefers any
  # tagged release over any pseudo-version.
  gitUnix="$(git --git-dir "${srcdir}/.git" log -1 --pretty='%ct')"
  gitDate="$(TZ=UTC date -u --date "@$gitUnix" +'%Y%m%d%H%M%S')"
  # generated version is now something like 'v0.0.0-20180719213702-cd5e2db'
  version="v0.0.0-${gitDate}-${commitShort}" # (using hyphens)
  pkgVersion="v0.0.0~${gitDate}.${commitShort}"  # (using tilde and periods)
  rpmRelease=0
fi

# deb and rpm packages require a tilde (~) instead of a hyphen (-) as separator
# between the version # and pre-release suffixes, otherwise pre-releases are
# sorted AFTER non-pre-release versions, which would prevent users from updating
# from a pre-release version to the "ga" version.
#
# For details, see this thread on the Debian mailing list:
# https://lists.debian.org/debian-policy/1998/06/msg00099.html
#
# For details, see the Fedora packaging guide:
# https://docs.fedoraproject.org/en-US/packaging-guidelines/Versioning/#_handling_non_sorting_versions_with_tilde_dot_and_caret
#
# The code below replaces hyphens with tildes. Note that an intermediate $tilde
# variable is needed to make this work on all versions of Bash. In some versions
# of Bash, the tilde would be substituted with $HOME (even when escaped (\~) or
# quoted ('~').
tilde='~'
pkgVersion="${version#v}"
pkgVersion="${pkgVersion//-/$tilde}"

echo "GENVER_VERSION=${version}"
echo "GENVER_PKG_VERSION=${pkgVersion}"
echo "GENVER_COMMIT=${commit}"
echo "GENVER_COMMIT_SHORT=${commitShort}"
echo "GENVER_RPM_RELEASE=${rpmRelease}"
