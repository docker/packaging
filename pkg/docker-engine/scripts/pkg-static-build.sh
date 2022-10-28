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

binext=$([ "$(xx-info os)" = "windows" ] && echo ".exe" || true)
pkg=github.com/docker/docker

# FIXME: remove when cross comp fixed (https://github.com/moby/moby/pull/43529)
buildTags="netgo osusergo static_build"
if pkg-config 'libsystemd' 2> /dev/null; then
  buildTags+=" journald"
fi

# -buildmode=pie is not supported on Windows arm64 and Linux mips*, ppc64be
# https://github.com/golang/go/blob/4aa1efed4853ea067d665a952eee77c52faac774/src/cmd/internal/sys/supported.go#L125-L131
# FIXME: remove when cross comp fixed (https://github.com/moby/moby/pull/43529)
case "$(xx-info os)/$(xx-info arch)" in
  windows/arm64 | linux/mips* | linux/ppc64) ;;
  *)
    dockerdBuildMode="-buildmode=pie"
    ;;
esac

# compile the Windows resources into the sources
# FIXME: remove when cross comp fixed (https://github.com/moby/moby/pull/43529)
if [ "$(xx-info os)" = "windows" ]; then
  (
    pushd ${SRCDIR}
      # FIXME: BINARY_SHORT_NAME deprecated, remove when 22.06 branch rebased with master
      BINARY_NAME="dockerd" BINARY_SHORT_NAME="dockerd" BINARY_FULLNAME="dockerd.exe" VERSION="${GENVER_VERSION}" GITCOMMIT="${GENVER_COMMIT}" . hack/make/.mkwinres
      go generate -v "./cmd/dockerd"
      # FIXME: BINARY_SHORT_NAME deprecated, remove when 22.06 branch rebased with master
      BINARY_NAME="docker-proxy" BINARY_SHORT_NAME="docker-proxy" BINARY_FULLNAME="docker-proxy.exe" VERSION="${GENVER_VERSION}" GITCOMMIT="${GENVER_COMMIT}" . hack/make/.mkwinres
      go generate -v "./cmd/docker-proxy"
    popd
  )
fi

(
  set -x
  pushd ${SRCDIR}
    # FIXME: use ./hack/make.sh binary-daemon when cross comp fixed (https://github.com/moby/moby/pull/43529)
    go build $dockerdBuildMode \
      -trimpath \
      -tags "$buildTags" \
      -installsuffix netgo \
      -ldflags "-w -extldflags -static -X ${pkg}/dockerversion.Version=${GENVER_VERSION} -X ${pkg}/dockerversion.GitCommit=${GENVER_COMMIT}" \
      -o "${BUILDDIR}/${PKG_NAME}/dockerd${binext}" ./cmd/dockerd
  popd
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/dockerd${binext}"
)

(
  set -x
  pushd ${SRCDIR}
    # FIXME: use ./hack/make.sh binary-proxy when cross comp fixed (https://github.com/moby/moby/pull/43529)
    CGO_ENABLED=0 go build \
      -trimpath \
      -tags "$buildTags" \
      -installsuffix netgo \
      -ldflags "-w -extldflags -static -X ${pkg}/dockerversion.Version=${GENVER_VERSION} -X ${pkg}/dockerversion.GitCommit=${GENVER_COMMIT}" \
      -o "${BUILDDIR}/${PKG_NAME}/docker-proxy${binext}" ./cmd/docker-proxy
  popd
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/docker-proxy${binext}"
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
