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

: "${DISTRO_NAME=}"
: "${DISTRO_RELEASE=}"
: "${DISTRO_ID=}"
: "${DISTRO_SUITE=}"

: "${PKG_NAME=}"
: "${PKG_PACKAGER=}"
: "${PKG_VENDOR=}"

: "${PKG_DEB_REVISION=}"
: "${PKG_DEB_EPOCH=}"

: "${SOURCE_DATE_EPOCH=}"
: "${OUTDIR=/out}"

set -e

if [ -z "$VERSION" ]; then
  echo >&2 "error: VERSION is required"
  exit 1
fi
if [ -z "$DISTRO_NAME" ]; then
  echo >&2 "error: DISTRO_NAME is required"
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

# Derive deb-compatible package version from VERSION (e.g. v0.1.0-beta.1 -> 0.1.0~beta.1)
tilde='~'
pkgVersion="${VERSION#v}"
pkgVersion="${pkgVersion//-/$tilde}"

gen-deb-changelog "$VERSION" "$pkgVersion" "$DISTRO_RELEASE" "$DISTRO_ID" "$DISTRO_SUITE" "$PKG_DEB_REVISION" "$PKG_DEB_EPOCH"

pkgoutput="${OUTDIR}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi
mkdir -p "${pkgoutput}"

set -x

GOARCH="$(xx-info arch)"
case "${GOARCH}" in
  amd64) KERNEL_ARTIFACT="nerdbox-kernel-x86_64"; INITRD_ARTIFACT="nerdbox-initrd-x86_64" ;;
  arm64) KERNEL_ARTIFACT="nerdbox-kernel-arm64_4k"; INITRD_ARTIFACT="nerdbox-initrd-arm64" ;;
  *)     echo "Unsupported arch: ${GOARCH}" >&2; exit 1 ;;
esac

# Install pre-built sbx binary
install -D -p -m 0755 /opt/sbx-bin/sbx /usr/bin/sbx

# Install runtime companion binaries
install -D -p -m 0755 "/opt/runtime-bin/containerd-shim-nerdbox-v1-linux-${GOARCH}" /usr/libexec/containerd-shim-nerdbox-v1
install -D -p -m 0755 "/opt/runtime-bin/mkfs.erofs-linux-${GOARCH}" /usr/libexec/mkfs.erofs
install -D -p -m 0755 "/opt/runtime-bin/mkfs.ext4-linux-${GOARCH}" /usr/libexec/mkfs.ext4
install -D -p -m 0644 "/opt/runtime-bin/${KERNEL_ARTIFACT}" "/usr/libexec/${KERNEL_ARTIFACT}"
install -D -p -m 0644 "/opt/runtime-bin/${INITRD_ARTIFACT}" "/usr/libexec/${INITRD_ARTIFACT}"
install -D -p -m 0755 "/opt/runtime-bin/libkrun-${GOARCH}.so" /usr/libexec/lib/libkrun.so

# Install AppArmor profile (picked up by dh_apparmor during dpkg-buildpackage)
install -D -p -m 0644 /opt/apparmor/docker-sbx-nerdbox-shim /usr/share/apparmor/docker-sbx-nerdbox-shim

chmod -x debian/control debian/copyright
VERSION=${VERSION} dpkg-buildpackage $PKG_DEB_BUILDFLAGS --host-arch $(xx-info debian-arch) --target-arch $(xx-info debian-arch)
cp /root/docker-* "${pkgoutput}"/
