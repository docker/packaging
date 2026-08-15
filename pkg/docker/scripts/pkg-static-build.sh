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

: "${DOCKER_VERSION=}"

: "${BUILDDIR=/work/build}"
: "${ENGINE_SRCDIR=/work/engine-src}"
: "${CLI_SRCDIR=/work/cli-src}"
: "${OUTDIR=/out}"

: "${TAGPREFIX=docker-}"

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

for l in $(gen-ver "${ENGINE_SRCDIR}"); do
  export "ENGINE_${l?}"
done

for l in $(TAGPREFIX= gen-ver "${CLI_SRCDIR}"); do
  export "CLI_${l?}"
done

version="${DOCKER_VERSION:-${ENGINE_GENVER_VERSION}}"
case "$version" in
  v*) ;;
  *) version="v${version}" ;;
esac
version_no_v="${version#v}"

export GO111MODULE
GO111MODULE=$(SRCDIR="${ENGINE_SRCDIR}" check-gomod)

xx-go --wrap
fix-cc

# prefer ld for cross-compiling arm64
# https://github.com/moby/moby/commit/f676dab8dc58c9eaa83b260c631a92d95a7a0b10
if [  "$(xx-info arch)" = "arm64" ]; then
  XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple
fi

binext=$([ "$(xx-info os)" = "windows" ] && echo ".exe" || true)

engine_builddir="${BUILDDIR}/docker-engine"
cli_builddir="${BUILDDIR}/docker-cli"
runtime_builddir="${BUILDDIR}/docker-runtime"
combined_builddir="${BUILDDIR}/docker"
runtime_srcdir="${BUILDDIR}/runtime-src"
containerd_srcdir="${runtime_srcdir}/containerd"
runc_srcdir="${runtime_srcdir}/runc"
runhcs_srcdir="${runtime_srcdir}/runhcs"
mkdir -p "$engine_builddir" "$cli_builddir" "$runtime_builddir" "$combined_builddir" "$runtime_srcdir"

dockerfile_arg() {
  local name="$1"
  local value
  value=$(sed -n -E "s/^ARG ${name}=(.*)$/\1/p" "${ENGINE_SRCDIR}/Dockerfile" | head -n1)
  value="${value#\"}"
  value="${value%\"}"
  if [ -z "$value" ]; then
    echo >&2 "error: ARG ${name} not found in ${ENGINE_SRCDIR}/Dockerfile"
    exit 1
  fi
  printf '%s\n' "$value"
}

fetch_git_ref() {
  local repo="$1"
  local ref="$2"
  local dest="$3"

  git init "$dest"
  git -C "$dest" remote add origin "$repo"
  git -C "$dest" fetch --depth 1 origin "$ref"
  git -C "$dest" checkout -q FETCH_HEAD
}

(
  set -x
  pushd "${ENGINE_SRCDIR}"
    CGO_ENABLED=1 VERSION="${version}" DOCKER_GITCOMMIT="${ENGINE_GENVER_COMMIT}" ./hack/make.sh binary
    mv "./bundles/binary-daemon/dockerd${binext}" "${engine_builddir}/"
    if [ "$(xx-info os)" != "windows" ]; then
      mv "./bundles/binary-daemon/docker-proxy${binext}" "${engine_builddir}/"
    fi
  popd
  xx-verify --static "${engine_builddir}/dockerd${binext}"
  if [ "$(xx-info os)" != "windows" ]; then
    xx-verify --static "${engine_builddir}/docker-proxy${binext}"
  fi
)

# TODO: build tini for windows
if [ "$(xx-info os)" != "windows" ]; then
  (
    set -x
    pushd "${ENGINE_SRCDIR}"
      # FIXME: can't use clang with tini
      CC=$(xx-info)-gcc PREFIX="${engine_builddir}" TMP_GOPATH="/go" hack/dockerfile/install/install.sh tini
    popd
    xx-verify --static "${engine_builddir}/docker-init"
  )
fi

(
  set -x
  pushd "${CLI_SRCDIR}"
    CGO_ENABLED=0 GO111MODULE=off VERSION="${version}" GITCOMMIT="${CLI_GENVER_COMMIT}" GO_LINKMODE=static TARGET="${cli_builddir}" ./scripts/build/binary
  popd
  xx-verify --static "${cli_builddir}/docker"
)

if [ "$(xx-info os)" = "linux" ] || [ "$(xx-info os)" = "windows" ]; then
  containerd_version=$(dockerfile_arg CONTAINERD_VERSION)

  (
    set -x
    fetch_git_ref "https://github.com/containerd/containerd.git" "$containerd_version" "$containerd_srcdir"
    containerd_revision=$(git -C "$containerd_srcdir" rev-parse HEAD)
    pushd "$containerd_srcdir"
      CC="$(xx-info)-gcc" CGO_ENABLED=0 GO111MODULE=on make STATIC=1 VERSION="${containerd_version}" REVISION="${containerd_revision}" bin/containerd
      if [ "$(xx-info os)" = "linux" ]; then
        CC="$(xx-info)-gcc" CGO_ENABLED=0 GO111MODULE=on make STATIC=1 VERSION="${containerd_version}" REVISION="${containerd_revision}" bin/containerd-shim-runc-v2
      fi
      CC="$(xx-info)-gcc" CGO_ENABLED=0 GO111MODULE=on make STATIC=1 VERSION="${containerd_version}" REVISION="${containerd_revision}" bin/ctr
      mv bin/containerd bin/ctr "$runtime_builddir/"
      if [ "$(xx-info os)" = "linux" ]; then
        mv bin/containerd-shim-runc-v2 "$runtime_builddir/"
      fi
    popd
    if [ "$(xx-info os)" = "windows" ]; then
      mv "${runtime_builddir}/containerd" "${runtime_builddir}/containerd.exe"
      mv "${runtime_builddir}/ctr" "${runtime_builddir}/ctr.exe"
    fi
    xx-verify --static "${runtime_builddir}/containerd${binext}"
    xx-verify --static "${runtime_builddir}/ctr${binext}"
    if [ "$(xx-info os)" = "linux" ]; then
      xx-verify --static "${runtime_builddir}/containerd-shim-runc-v2"
    fi
  )
fi

if [ "$(xx-info os)" = "linux" ]; then
  runc_version=$(dockerfile_arg RUNC_VERSION)

  (
    set -x
    fetch_git_ref "https://github.com/opencontainers/runc.git" "$runc_version" "$runc_srcdir"
    pushd "$runc_srcdir"
      CGO_ENABLED=1 GO111MODULE=on make static
      mv runc "$runtime_builddir/"
    popd
    xx-verify --static "${runtime_builddir}/runc"
  )
fi

if [ "$(xx-info os)" = "windows" ]; then
  runhcs_ref=$(cat "${containerd_srcdir}/script/setup/runhcs-version")

  (
    set -x
    fetch_git_ref "https://github.com/Microsoft/hcsshim.git" "$runhcs_ref" "$runhcs_srcdir"
    pushd "$runhcs_srcdir"
      GO111MODULE=on go build -mod=vendor -o "${runtime_builddir}/containerd-shim-runhcs-v1.exe" ./cmd/containerd-shim-runhcs-v1
    popd
    xx-verify --static "${runtime_builddir}/containerd-shim-runhcs-v1.exe"
  )
fi

cp "${engine_builddir}"/* "$combined_builddir/"
cp -L "${cli_builddir}/docker" "$combined_builddir/docker${binext}"
if [ "$(xx-info os)" = "linux" ] || [ "$(xx-info os)" = "windows" ]; then
  cp "${runtime_builddir}"/* "$combined_builddir/"
fi

pkgoutput="$OUTDIR/static/$(xx-info os)/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi
mkdir -p "${pkgoutput}"

workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
mkdir -p "$workdir/docker"
(
  set -x
  cp "${combined_builddir}"/* "$workdir/docker/"
  cp "${ENGINE_SRCDIR}/LICENSE" "$workdir/docker/engine.LICENSE"
  cp "${ENGINE_SRCDIR}/README.md" "$workdir/docker/engine.README.md"
  cp "${CLI_SRCDIR}/LICENSE" "$workdir/docker/cli.LICENSE"
  cp "${CLI_SRCDIR}/README.md" "$workdir/docker/cli.README.md"
  if [ -d "$containerd_srcdir" ]; then
    cp "${containerd_srcdir}/LICENSE" "$workdir/docker/containerd.LICENSE"
    cp "${containerd_srcdir}/README.md" "$workdir/docker/containerd.README.md"
  fi
  if [ -d "$runc_srcdir" ]; then
    cp "${runc_srcdir}/LICENSE" "$workdir/docker/runc.LICENSE"
    cp "${runc_srcdir}/README.md" "$workdir/docker/runc.README.md"
  fi
  if [ -d "$runhcs_srcdir" ]; then
    cp "${runhcs_srcdir}/LICENSE" "$workdir/docker/runhcs.LICENSE"
    cp "${runhcs_srcdir}/README.md" "$workdir/docker/runhcs.README.md"
  fi
)
if [ "$(xx-info os)" = "windows" ]; then
  pkgfile="${pkgoutput}/docker-${version_no_v}.zip"
  (
    set -x
    cd "$workdir"
    zip -r "$pkgfile" docker
  )
else
  pkgfile="${pkgoutput}/docker-${version_no_v}.tgz"
  (
    set -x
    tar -czf "$pkgfile" -C "$workdir" docker
  )
fi
(
  set -x
  cd "$pkgoutput"
  sha256sum "${pkgfile##*/}" > "${pkgfile##*/}.sha256"
)
