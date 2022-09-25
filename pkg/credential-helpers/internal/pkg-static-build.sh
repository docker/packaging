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

: "${BUILDDIR=/work/build}"
: "${SRCDIR=/work/src}"
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

# FIXME: CC is set to a cross package: https://github.com/docker/packaging/pull/25#issuecomment-1256594482
if ! command "$(go env CC)" &> /dev/null; then
  go env -w CC=gcc
fi

xx-go --wrap

case "$(xx-info os)" in
  darwin)
    (
      go install std
      set -x
      pushd ${SRCDIR}
        make build-osxkeychain VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR="${BUILDDIR}/${PKG_NAME}"
        make build-pass VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR="${BUILDDIR}/${PKG_NAME}"
      popd
      xx-verify "${BUILDDIR}/${PKG_NAME}/docker-credential-osxkeychain"
      xx-verify "${BUILDDIR}/${PKG_NAME}/docker-credential-pass"
    )
  ;;
  linux)
    (
      set -x
      pushd ${SRCDIR}
        make build-pass VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR="${BUILDDIR}/${PKG_NAME}"
        make build-secretservice VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR="${BUILDDIR}/${PKG_NAME}"
      popd
      xx-verify "${BUILDDIR}/${PKG_NAME}/docker-credential-pass"
      xx-verify "${BUILDDIR}/${PKG_NAME}/docker-credential-secretservice"
    )
  ;;
  windows)
    (
      set -x
      pushd ${SRCDIR}
        make build-wincred VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR="${BUILDDIR}/${PKG_NAME}"
      popd
      mv "${BUILDDIR}/${PKG_NAME}/docker-credential-wincred" "${BUILDDIR}/${PKG_NAME}/docker-credential-wincred.exe"
      xx-verify "${BUILDDIR}/${PKG_NAME}/docker-credential-wincred.exe"
    )
  ;;
esac

pkgoutput="/out/static/$(xx-info os)/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi
mkdir -p "${pkgoutput}"

cd "$BUILDDIR"
for pkgname in *; do
  workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
  mkdir -p "$workdir/${pkgname}"
  (
    set -x
    cp "${pkgname}"/* ${SRCDIR}/LICENSE ${SRCDIR}/README.md "$workdir/${pkgname}/"
  )
  if [ "$(xx-info os)" = "windows" ]; then
    (
      set -x
      cd "$workdir"
      zip -r "${pkgoutput}/${pkgname}_${CREDENTIAL_HELPERS_VERSION#v}.zip" "${pkgname}"
    )
  else
    (
      set -x
      tar -czf "${pkgoutput}/${pkgname}_${CREDENTIAL_HELPERS_VERSION#v}.tgz" -C "$workdir" "${pkgname}"
    )
  fi
done
