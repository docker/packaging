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

# remove once llvm 12 available on debian
# https://github.com/docker/cli/blob/65438e008c20a6125a1319eca07dcc3d7d4e38eb/Dockerfile#L30-L36
if [ "$(xx-info os)/$(xx-info arch)" != "darwin/amd64" ]; then
  ln -sfnT /bin/true /usr/bin/llvm-strip
fi

# prefer ld for cross-compiling arm64
# https://github.com/docker/cli/pull/3493/commits/d45030380d8e1f8eadcb9512e81cfc63885aa638
if [  "$(xx-info arch)" = "arm64" ]; then
  XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple
fi

(
  set -x
  pushd ${SRCDIR}
    VERSION=${GENVER_VERSION} GITCOMMIT=${GENVER_COMMIT} GO_LINKMODE=static TARGET=${BUILDDIR}/${PKG_NAME} ./scripts/build/binary
  popd
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/docker"
)

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
