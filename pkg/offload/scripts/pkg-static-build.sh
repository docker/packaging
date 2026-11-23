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
: "${BUILD_ENV_FILE=}"

: "${PKG_NAME=}"

: "${BUILDDIR=/work/build}"
: "${SRCDIR=/usr/local/src/offload}"
: "${NOTICESDIR=/usr/local/src/notices}"
: "${OUTDIR=/out}"

set -e

if [ -z "$VERSION" ]; then
  echo >&2 "error: VERSION is required"
  exit 1
fi
case "$VERSION" in
  v*) ;;
  *) echo >&2 "error: VERSION must start with v, got $VERSION"; exit 1 ;;
esac
if [ -z "$PKG_NAME" ]; then
  echo >&2 "error: PKG_NAME is required"
  exit 1
fi
if [ -z "$OUTDIR" ]; then
  echo >&2 "error: OUTDIR is required"
  exit 1
fi

if ! command -v xx-info &> /dev/null; then
  echo >&2 "error: xx cross compilation helper is required"
  exit 1
fi

mkdir -p "$OUTDIR" "$BUILDDIR"

binext=$([ "$(xx-info os)" = "windows" ] && echo ".exe" || true)
bin="${BUILDDIR}/docker-offload${binext}"

# Build from source, as the deb and rpm builds do. The binaries are unsigned.
(
  set -x
  xx-go --wrap
  make -C "$SRCDIR" ce-release VERSION="$VERSION" COMMIT="$COMMIT" BUILD="$BUILD" DATE="$DATE" \
    BUILD_ENV_FILE="$BUILD_ENV_FILE"
  install -m 0755 "${SRCDIR}/dist/docker-offload${binext}" "$bin"
  xx-verify --static "$bin"
)

for doc in LICENSE README.md; do
  if [ ! -f "${SRCDIR}/${doc}" ]; then
    echo >&2 "error: no ${doc} in ${SRCDIR}; pass the source tree as the src named context"
    exit 1
  fi
done
if [ ! -s "${NOTICESDIR}/THIRD-PARTY-NOTICES" ]; then
  echo >&2 "error: no THIRD-PARTY-NOTICES in ${NOTICESDIR}; pass the release notices as the notices named context"
  exit 1
fi

pkgoutput="$OUTDIR/static/$(xx-info os)/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi
mkdir -p "${pkgoutput}"

workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
mkdir -p "$workdir/cli-plugins" "$workdir/doc"
(
  set -x
  cp "$bin" "$workdir/cli-plugins/"
  cp "${SRCDIR}/LICENSE" "${SRCDIR}/README.md" "${NOTICESDIR}/THIRD-PARTY-NOTICES" "$workdir/doc/"
)
if [ "$(xx-info os)" = "windows" ]; then
  pkgfile="${pkgoutput}/${PKG_NAME}_${VERSION#v}.zip"
  (
    set -x
    cd "$workdir"
    zip -r "$pkgfile" cli-plugins doc
  )
else
  pkgfile="${pkgoutput}/${PKG_NAME}_${VERSION#v}.tgz"
  (
    set -x
    tar -czf "$pkgfile" -C "$workdir" cli-plugins doc
  )
fi
write-sha256sum "$pkgfile"
