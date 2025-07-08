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
: "${LIBSECCOMP_SRCDIR=/work/libseccomp-src}"
: "${RUNHCS_SRCDIR=/work/runhcs-src}"

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

# FIXME: should be built using clang but needs https://github.com/opencontainers/runc/pull/3465
export CC=$(xx-info)-gcc

mkdir -p ${BUILDDIR}/${PKG_NAME}

if [[ "$(xx-info os)" = "windows" ]] && [ "$(xx-info arch)" != "amd64" ]; then
  # https://github.com/containerd/containerd/blob/2af24b5629859019a7201c59dda611d25d608e65/.github/workflows/ci.yml#L162-L165
  export CGO_ENABLED=0
fi

(
  set -x
  pushd ${SRCDIR}
    make STATIC=1 VERSION="${GENVER_VERSION}" REVISION="${GENVER_COMMIT}" bin/containerd
    if [ "$(xx-info os)" != "windows" ]; then
      make STATIC=1 VERSION="${GENVER_VERSION}" REVISION="${GENVER_COMMIT}" bin/containerd-shim-runc-v2
    fi
    make STATIC=1 VERSION="${GENVER_VERSION}" REVISION="${GENVER_COMMIT}" bin/ctr
    mv bin/* "${BUILDDIR}/${PKG_NAME}"
  popd
  if [ "$(xx-info os)" = "windows" ]; then
    mv "${BUILDDIR}/${PKG_NAME}/containerd" "${BUILDDIR}/${PKG_NAME}/containerd.exe"
    mv "${BUILDDIR}/${PKG_NAME}/ctr" "${BUILDDIR}/${PKG_NAME}/ctr.exe"
  fi
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/containerd${binext}"
  if [ "$(xx-info os)" != "windows" ]; then
    xx-verify --static "${BUILDDIR}/${PKG_NAME}/containerd-shim-runc-v2${binext}"
  fi
  xx-verify --static "${BUILDDIR}/${PKG_NAME}/ctr${binext}"
)

if [ "$(xx-info os)" = "windows" ]; then
  (
    set -x
    pushd ${RUNHCS_SRCDIR}
      GO111MODULE=on go build -mod=vendor -o "${BUILDDIR}/${PKG_NAME}/containerd-shim-runhcs-v1.exe" ./cmd/containerd-shim-runhcs-v1
    popd
    xx-verify --static  "${BUILDDIR}/${PKG_NAME}/containerd-shim-runhcs-v1.exe"
  )
else
  (
    set -x
    pushd ${LIBSECCOMP_SRCDIR}
      ./configure --host=$(xx-clang --print-target-triple) --enable-static --disable-shared
      make install
      make clean
    popd
  )

  (
    set -x
    pushd ${RUNC_SRCDIR}
      make static
      mv runc "${BUILDDIR}/${PKG_NAME}"
    popd
    xx-verify --static  "${BUILDDIR}/${PKG_NAME}/runc"
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
    if [ "$(xx-info os)" = "windows" ]; then
      cp ${RUNHCS_SRCDIR}/LICENSE "$workdir/${pkgname}/runhcs.LICENSE"
      cp ${RUNHCS_SRCDIR}/README.md "$workdir/${pkgname}/runhcs.README.md"
    else
      cp ${RUNC_SRCDIR}/LICENSE "$workdir/${pkgname}/runc.LICENSE"
      cp ${RUNC_SRCDIR}/README.md "$workdir/${pkgname}/runc.README.md"
    fi
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
