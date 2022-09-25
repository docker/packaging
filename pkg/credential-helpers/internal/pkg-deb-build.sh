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

: "${CREDENTIAL_HELPERS_VERSION=}"

: "${PKG_NAME=}"
: "${PKG_RELEASE=}"
: "${PKG_DISTRO=}"
: "${PKG_SUITE=}"
: "${PKG_PACKAGER=}"
: "${PKG_VENDOR=}"

: "${PKG_DEB_REVISION=}"
: "${PKG_DEB_EPOCH=}"

: "${SOURCE_DATE_EPOCH=}"
: "${OUTDIR=/out}"

set -e

if [ -z "$PKG_RELEASE" ]; then
  echo >&2 "error: PKG_RELEASE is required"
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

tilde='~'
debVersion="${CREDENTIAL_HELPERS_VERSION#v}"
debVersion="${debVersion//-/$tilde}"

cat > "debian/changelog" <<-EOF
${PKG_NAME} (${PKG_DEB_EPOCH}$([ -n "$PKG_DEB_EPOCH" ] && echo ":")${debVersion}-${PKG_DEB_REVISION}) $PKG_SUITE; urgency=low
  * Version: $CREDENTIAL_HELPERS_VERSION
 -- $(awk -F ': ' '$1 == "Maintainer" { print $2; exit }' debian/control)  $(date --rfc-2822)
EOF

# FIXME: CC is set to a cross package: https://github.com/docker/packaging/pull/25#issuecomment-1256594482
if ! command "$(go env CC)" &> /dev/null; then
  go env -w CC=gcc
fi

xx-go --wrap

pkgoutput="${OUTDIR}/${PKG_DISTRO}/${PKG_SUITE}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi

set -x

chmod -x debian/compat debian/control debian/docs
dpkg-buildpackage $PKG_DEB_BUILDFLAGS --host-arch $(xx-info debian-arch) --target-arch $(xx-info debian-arch)
mkdir -p "${pkgoutput}"
cp /root/docker-credential-* "${pkgoutput}"/
