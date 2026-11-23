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

: "${VERSION=}"
: "${COMMIT=}"
: "${BUILD=}"
: "${DATE=}"

: "${DISTRO_NAME=}"
: "${DISTRO_RELEASE=}"
: "${DISTRO_ID=}"
: "${DISTRO_SUITE=}"

: "${PKG_NAME=}"
: "${PKG_PACKAGER=}"
: "${PKG_VENDOR=}"

: "${PKG_RPM_RELEASE=}"

: "${SOURCE_DATE_EPOCH=}"
: "${SRCDIR=/usr/local/src/offload}"
: "${NOTICESDIR=/usr/local/src/notices}"
: "${OUTDIR=/out}"
: "${BUILD_ENV_FILE=}"

set -e

if [ -z "$VERSION" ]; then
  echo >&2 "error: VERSION is required"
  exit 1
fi
case "$VERSION" in
  v*) ;;
  *) echo >&2 "error: VERSION must start with v, got $VERSION"; exit 1 ;;
esac
if [ -z "$DISTRO_NAME" ]; then
  echo >&2 "error: DISTRO_NAME is required"
  exit 1
fi
if [ -z "$OUTDIR" ]; then
  echo >&2 "error: OUTDIR is required"
  exit 1
fi
if [ ! -f "${SRCDIR}/Makefile" ]; then
  echo >&2 "error: no Makefile in ${SRCDIR}; pass the source tree as the src named context"
  exit 1
fi

for doc in "${SRCDIR}/LICENSE" "${NOTICESDIR}/THIRD-PARTY-NOTICES"; do
  if [ ! -s "$doc" ]; then
    echo >&2 "error: ${doc} is missing or empty; pass the source tree as the src named context and the release notices as the notices named context"
    exit 1
  fi
done

mkdir -p "$OUTDIR"

if ! command -v xx-info &> /dev/null; then
  echo >&2 "error: xx cross compilation helper is required"
  exit 1
fi

# Derive rpm-compatible package version from VERSION.
# Tagged pre-release versions use ~ so they sort lower:
#   v0.1.0-beta.1        -> 0.1.0~beta.1
tilde='~'
pkgVersion="${VERSION#v}"
pkgVersion="${pkgVersion//-/$tilde}"

# rpm rejects macros with an empty body, so optional values default to %{nil}.
nil='%{nil}'
rpmDefine=(
  --define "_version ${pkgVersion}"
  --define "_origversion ${VERSION}"
  --define "_release ${PKG_RPM_RELEASE:-1}"
  --define "_srcdir ${SRCDIR}"
  --define "_noticesdir ${NOTICESDIR}"
  --define "_commit ${COMMIT:-$nil}"
  --define "_buildnum ${BUILD:-$nil}"
  --define "_date ${DATE:-$nil}"
  --define "_buildenvfile ${BUILD_ENV_FILE:-$nil}"
)

pkgoutput="${OUTDIR}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi

set -x

rpmbuild --target $(xx-info rhel-arch) $PKG_RPM_BUILDFLAGS "${rpmDefine[@]}" /root/rpmbuild/SPECS/*.spec
mkdir -p "${pkgoutput}"
cp ./RPMS/*/*.* "${pkgoutput}"/
if [ "$(ls -A ./SRPMS)" ]; then
  cp ./SRPMS/* "${pkgoutput}"/
fi
