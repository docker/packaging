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

: "${BUILDX_VERSION=}"

: "${PKG_NAME=}"
: "${PKG_DISTRO=}"
: "${PKG_SUITE=}"
: "${PKG_PACKAGER=}"
: "${PKG_VENDOR=}"

: "${SOURCE_DATE_EPOCH=}"
: "${OUTDIR=/out}"

set -e

if [ -z "$OUTDIR" ]; then
  echo >&2 "error: OUTDIR is required"
  exit 1
fi

mkdir -p "$OUTDIR"

if ! command -v xx-info &> /dev/null; then
  echo >&2 "error: xx cross compilation helper is required"
  exit 1
fi

pkgoutput="${OUTDIR}/${PKG_DISTRO}"
if [ "${PKG_DISTRO}" = "static" ]; then
  pkgoutput="${pkgoutput}/$(xx-info os)"
else
  pkgoutput="${pkgoutput}/${PKG_SUITE}"
fi

pkgoutput="${pkgoutput}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi

mkdir -p "${pkgoutput}"
if [ "$PKG_TYPE" = "static" ]; then
  workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
  mkdir -p "$workdir/${PKG_NAME}"
  echo "using static packager"
  (
    set -x
    cp /src/LICENSE /src/README.md "$workdir/${PKG_NAME}/"
  )
  if [ "$(xx-info os)" = "windows" ]; then
    (
      set -x
      cp /usr/bin/buildx "$workdir/${PKG_NAME}/docker-buildx.exe"
      cd "$workdir"
      zip -r "$pkgoutput/${PKG_NAME}_${BUILDX_VERSION#v}.zip" ${PKG_NAME}
    )
  else
    (
      set -x
      cp /usr/bin/buildx "$workdir/${PKG_NAME}/docker-buildx"
      tar -czf "$pkgoutput/${PKG_NAME}_${BUILDX_VERSION#v}.tgz" -C "$workdir" ${PKG_NAME}
    )
  fi
elif [ "$(xx-info os)" = "linux" ]; then
  case $PKG_TYPE in
    apk)
      arch=$(xx-info alpine-arch);;
    deb)
      arch=$(xx-info debian-arch);;
    rpm)
      arch=$(xx-info rhel-arch);;
  esac
  (
    set -x
    ARCH="${arch}" VERSION="${BUILDX_VERSION}" RELEASE="$PKG_REVISION" VENDOR="${PKG_VENDOR}" PACKAGER="${PKG_PACKAGER}" nfpm package --config ./nfpm.yml --packager "$PKG_TYPE" --target "$pkgoutput"
  )
else
  rm -rf "${pkgoutput}"
fi
