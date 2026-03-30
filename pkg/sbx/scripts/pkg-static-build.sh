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

: "${NIGHTLY_BUILD=}"
: "${VERSION=}"

: "${PKG_NAME=}"

: "${BUILDDIR=/work/build}"
: "${OUTDIR=/out}"

set -e

if [ -z "$VERSION" ]; then
  echo >&2 "error: VERSION is required"
  exit 1
fi
if [ -z "$OUTDIR" ]; then
  echo >&2 "error: OUTDIR is required"
  exit 1
fi

mkdir -p "$OUTDIR"

if ! command -v xx-info &> /dev/null; then
  echo >&2 "error: xx cross compilation helper is required"
  exit 1
fi

# Determine binary name based on target OS
binext=$([ "$(xx-info os)" = "windows" ] && echo ".exe" || true)

GOARCH="$(xx-info arch)"
case "${GOARCH}" in
  amd64) KERNEL_ARTIFACT="nerdbox-kernel-x86_64"; INITRD_ARTIFACT="nerdbox-initrd-x86_64" ;;
  arm64) KERNEL_ARTIFACT="nerdbox-kernel-arm64_4k"; INITRD_ARTIFACT="nerdbox-initrd-arm64" ;;
  *)     echo "Unsupported arch: ${GOARCH}" >&2; exit 1 ;;
esac

# Copy pre-built binaries
mkdir -p "${BUILDDIR}/${PKG_NAME}"
(
  set -x
  install -p -m 0755 /opt/sbx-bin/sbx${binext} "${BUILDDIR}/${PKG_NAME}/sbx${binext}"
  install -p -m 0755 "/opt/runtime-bin/containerd-shim-nerdbox-v1-linux-${GOARCH}" "${BUILDDIR}/${PKG_NAME}/containerd-shim-nerdbox-v1"
  install -p -m 0755 "/opt/runtime-bin/mkfs.erofs-linux-${GOARCH}" "${BUILDDIR}/${PKG_NAME}/mkfs.erofs"
  install -p -m 0755 "/opt/runtime-bin/mkfs.ext4-linux-${GOARCH}" "${BUILDDIR}/${PKG_NAME}/mkfs.ext4"
  install -p -m 0644 "/opt/runtime-bin/${KERNEL_ARTIFACT}" "${BUILDDIR}/${PKG_NAME}/${KERNEL_ARTIFACT}"
  install -p -m 0644 "/opt/runtime-bin/${INITRD_ARTIFACT}" "${BUILDDIR}/${PKG_NAME}/${INITRD_ARTIFACT}"
  install -p -m 0755 "/opt/runtime-bin/libkrun-${GOARCH}.so" "${BUILDDIR}/${PKG_NAME}/libkrun.so"
  install -p -m 0644 /opt/notices/THIRD-PARTY-NOTICES "${BUILDDIR}/${PKG_NAME}/THIRD-PARTY-NOTICES"
  install -p -m 0644 /opt/licenses/LICENSE "${BUILDDIR}/${PKG_NAME}/LICENSE"
  install -p -m 0644 /opt/licenses/GPL-2.0 "${BUILDDIR}/${PKG_NAME}/GPL-2.0"
  install -p -m 0644 /opt/licenses/Apache-2.0 "${BUILDDIR}/${PKG_NAME}/Apache-2.0"
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
    cp -r "${pkgname}"/* "$workdir/${pkgname}/"
  )
  if [ "$(xx-info os)" = "windows" ]; then
    (
      set -x
      cd "$workdir"
      zip -r "${pkgoutput}/${pkgname}_${VERSION#v}.zip" "${pkgname}"
    )
  else
    (
      set -x
      tar -czf "${pkgoutput}/${pkgname}_${VERSION#v}.tgz" -C "$workdir" "${pkgname}"
    )
  fi
done
