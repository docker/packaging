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

for l in $(gen-ver "${SRCDIR}"); do
  export "${l?}"
done

xx-go --wrap
fix-cc

# prefer ld for cross-compiling arm64
# https://github.com/moby/moby/commit/f676dab8dc58c9eaa83b260c631a92d95a7a0b10
if [  "$(xx-info arch)" = "arm64" ]; then
  XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple
fi

binext=$([ "$(xx-info os)" = "windows" ] && echo ".exe" || true)
mkdir -p ${BUILDDIR}/${PKG_NAME}

(
  set -x
  pushd ${SRCDIR}
    CGO_ENABLED=1 VERSION=${GENVER_VERSION} DOCKER_GITCOMMIT=${GENVER_COMMIT} ./hack/make.sh binary
    mv "./bundles/binary-daemon/dockerd${binext}" "${BUILDDIR}/${PKG_NAME}/"
    if [ "$(xx-info os)" != "windows" ]; then
      mv "./bundles/binary-daemon/docker-proxy${binext}" "${BUILDDIR}/${PKG_NAME}/"
    fi
  popd
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/dockerd${binext}"
  if [ "$(xx-info os)" != "windows" ]; then
    xx-verify --static "${BUILDDIR}/${PKG_NAME}/docker-proxy${binext}"
  fi
)

# TODO: build tini for windows
if [ "$(xx-info os)" != "windows" ]; then
  (
    set -x
    pushd ${SRCDIR}
      # FIXME: can't use clang with tini
      CC=$(xx-info)-gcc PREFIX="${BUILDDIR}/${PKG_NAME}" TMP_GOPATH="/go" hack/dockerfile/install/install.sh tini
    popd
    xx-verify --static "${BUILDDIR}/${PKG_NAME}/docker-init"
  )
fi

pkgoutput="$OUTDIR/static/$(xx-info os)/$(xx-info arch)"
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
      zip -r "${pkgoutput}/${pkgname}_${GENVER_VERSION#v}.zip" "${pkgname}"
    )
  else
    (
      set -x
      tar -czf "${pkgoutput}/${pkgname}_${GENVER_VERSION#v}.tgz" -C "$workdir" "${pkgname}"
    )
  fi
done
