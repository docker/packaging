#!/usr/bin/env bash

# Copyright 2026 Docker Packaging authors
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

: "${NIGHTLY_BUILD=}"
: "${VERSION=}"

: "${DISTRO_NAME=}"
: "${DISTRO_RELEASE=}"
: "${DISTRO_ID=}"
: "${DISTRO_SUITE=}"

: "${PKG_NAME=}"
: "${PKG_PACKAGER=}"
: "${PKG_VENDOR=}"

: "${PKG_RPM_RELEASE=}"

: "${SOURCE_DATE_EPOCH=}"
: "${OUTDIR=/out}"

set -e

if [ -z "$VERSION" ]; then
  echo >&2 "error: VERSION is required"
  exit 1
fi
if [ -z "$DISTRO_NAME" ]; then
  echo >&2 "error: DISTRO_NAME is required"
  exit 1
fi
if [ -z "$OUTDIR" ]; then
  echo >&2 "error: OUTDIR is required"
  exit 1
fi

mkdir -p "$OUTDIR"

if ! command -v xx-info &> /dev/null; then
  echo >&2 "error: xx cross compilation helper is required"
  exit 1
fi

# Derive rpm-compatible package version from VERSION.
# Nightly builds use + so they sort higher than the base release:
#   v0.24.1-25-g9cf02a7d -> 0.24.1+25~g9cf02a7d
# Tagged pre-release versions use ~ so they sort lower:
#   v0.1.0-beta.1        -> 0.1.0~beta.1
tilde='~'
pkgVersion="${VERSION#v}"
if [ -n "$NIGHTLY_BUILD" ]; then
  pkgVersion="${pkgVersion/-/+}"
fi
pkgVersion="${pkgVersion//-/$tilde}"

rpmDefine=(
  --define "_version ${pkgVersion}"
  --define "_origversion ${VERSION}"
  --define "_release ${PKG_RPM_RELEASE:-1}"
)

pkgoutput="${OUTDIR}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi

set -x

# Install the prebuilt plugin. The spec packages it from here.
install -D -p -m 0755 "/opt/offload-bin/docker-offload-linux-$(xx-info arch)" \
  /usr/local/libexec/docker/cli-plugins/docker-offload

rpmbuild --target $(xx-info rhel-arch) $PKG_RPM_BUILDFLAGS "${rpmDefine[@]}" /root/rpmbuild/SPECS/*.spec
mkdir -p "${pkgoutput}"
cp ./RPMS/*/*.* "${pkgoutput}"/
if [ "$(ls -A ./SRPMS)" ]; then
  cp ./SRPMS/* "${pkgoutput}"/
fi
