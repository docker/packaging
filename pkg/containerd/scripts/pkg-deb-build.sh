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

: "${NIGHTLY_BUILD=}"

: "${PKG_NAME=}"
: "${PKG_RELEASE=}"
: "${PKG_DISTRO=}"
: "${PKG_DISTRO_ID=}"
: "${PKG_DISTRO_SUITE=}"
: "${PKG_PACKAGER=}"
: "${PKG_VENDOR=}"

: "${PKG_DEB_REVISION=}"
: "${PKG_DEB_EPOCH=}"

: "${SOURCE_DATE_EPOCH=}"
: "${SRCDIR=/work/src}"
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

for l in $(gen-ver "${SRCDIR}"); do
  export "${l?}"
done

xx-go --wrap
fix-cc

gen-deb-changelog "$GENVER_VERSION" "$GENVER_PKG_VERSION" "$PKG_DISTRO" "$PKG_DISTRO_ID" "$PKG_DISTRO_SUITE" "$PKG_DEB_REVISION" "$PKG_DEB_EPOCH"

pkgoutput="${OUTDIR}/${PKG_DISTRO}/${PKG_DISTRO_SUITE}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi
mkdir -p "${pkgoutput}"

set -x

sed 's#/usr/local/bin/containerd#/usr/bin/containerd#g' "${SRCDIR}/containerd.service" > /common/containerd.service

chmod -x debian/compat debian/control debian/copyright debian/manpages
VERSION=${GENVER_VERSION} REVISION=${GENVER_COMMIT} dpkg-buildpackage $PKG_DEB_BUILDFLAGS --host-arch $(xx-info debian-arch) --target-arch $(xx-info debian-arch)
cp /root/${PKG_NAME}* "${pkgoutput}"/
