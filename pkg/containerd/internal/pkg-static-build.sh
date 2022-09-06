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

: "${CONTAINERD_VERSION=}"

: "${BUILDDIR=/work/build}"
: "${SRCDIR=/work/src}"
: "${OUTDIR=/out}"

: "${RUNC_SRCDIR=/work/runc-src}"

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

# TODO: add support for cross comp
if xx-info is-cross; then
  echo >&2 "warning: cross compilation with $(xx-info arch) not supported"
  exit 0
fi

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
    cp ${RUNC_SRCDIR}/LICENSE "$workdir/${pkgname}/runc.LICENSE"
    cp ${RUNC_SRCDIR}/README.md "$workdir/${pkgname}/runc.README.md"
  )
  if [ "$(xx-info os)" = "windows" ]; then
    (
      set -x
      cd "$workdir"
      zip -r "${pkgoutput}/${pkgname}_${CONTAINERD_VERSION#v}.zip" "${pkgname}"
    )
  else
    (
      set -x
      tar -czf "${pkgoutput}/${pkgname}_${CONTAINERD_VERSION#v}.tgz" -C "$workdir" "${pkgname}"
    )
  fi
done
