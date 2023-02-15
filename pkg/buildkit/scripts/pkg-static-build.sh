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

for l in $(gen-ver "${SRCDIR}"); do
  export "${l?}"
done

xx-go --wrap
fix-cc

binext=$([ "$(xx-info os)" = "windows" ] && echo ".exe" || true)
mkdir -p ${BUILDDIR}/${PKG_NAME}

(
  set -x
  pushd ${SRCDIR}
    go build \
      -mod=vendor \
      -trimpath \
      -ldflags "-X github.com/moby/buildkit/version.Version=${GENVER_VERSION} -X github.com/moby/buildkit/version.Revision=${GENVER_COMMIT} -X github.com/moby/buildkit/version.Package=github.com/moby/buildkit -extldflags '-static'" \
      -tags "urfave_cli_no_docs osusergo netgo static_build seccomp" \
      -o "${BUILDDIR}/${PKG_NAME}/buildctl${binext}" \
      ./cmd/buildctl
  popd
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/buildctl${binext}"
)

if [ "$(xx-info os)" != "darwin" ]; then
  (
    set -x
    pushd ${SRCDIR}
      go build \
        -mod=vendor \
        -trimpath \
        -ldflags "-X github.com/moby/buildkit/version.Version=${GENVER_VERSION} -X github.com/moby/buildkit/version.Revision=${GENVER_COMMIT} -X github.com/moby/buildkit/version.Package=github.com/moby/buildkit -extldflags '-static'" \
        -tags "urfave_cli_no_docs osusergo netgo static_build seccomp" \
        -o "${BUILDDIR}/${PKG_NAME}/buildkitd${binext}" \
        ./cmd/buildkitd
    popd
    xx-verify --static "${BUILDDIR}/${PKG_NAME}/buildkitd${binext}"
  )
fi

if [ "$(xx-info os)" = "linux" ]; then
  (
    set -x
    pushd ${RUNC_SRCDIR}
      CGO_ENABLED=1 make static
      mv runc "${BUILDDIR}/${PKG_NAME}/buildkit-runc"
    popd
    xx-verify --static  "${BUILDDIR}/${PKG_NAME}/buildkit-runc"
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
