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

: "${SBOM_VERSION=}"

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

xx-go --wrap

# FIXME: CC is set to a cross package in Go release: https://github.com/docker/packaging/pull/25#issuecomment-1256594482
if [ "$(go env CC)" = "$(xx-info triple)-gcc" ] && ! command "$(go env CC)" &> /dev/null; then
  go env -w CC=gcc
fi

binext=$([ "$(xx-info os)" = "windows" ] && echo ".exe" || true)
pkg=github.com/docker/sbom-cli-plugin
if [ -d "${SRCDIR}" ]; then
  commit="$(git --git-dir ${SRCDIR}/.git rev-parse HEAD)"
fi

(
  set -x
  pushd ${SRCDIR}
    go build \
      -trimpath \
      -ldflags="-s -w -X ${pkg}/internal/version.version=${SBOM_VERSION} -X ${pkg}/internal/version.gitCommit=${commit}" \
      -o "${BUILDDIR}/${PKG_NAME}/docker-sbom${binext}"
  popd
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/docker-sbom${binext}"
)

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
      zip -r "${pkgoutput}/${pkgname}_${SBOM_VERSION#v}.zip" "${pkgname}"
    )
  else
    (
      set -x
      tar -czf "${pkgoutput}/${pkgname}_${SBOM_VERSION#v}.tgz" -C "$workdir" "${pkgname}"
    )
  fi
done
