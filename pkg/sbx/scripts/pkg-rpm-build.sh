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

: "${PKG_RPM_RELEASE=}"

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

# Derive rpm-compatible package version from VERSION (e.g. v0.1.0-beta.1 -> 0.1.0~beta.1)
tilde='~'
pkgVersion="${VERSION#v}"
pkgVersion="${pkgVersion//-/$tilde}"

GOARCH="$(xx-info arch)"
case "${GOARCH}" in
  amd64) KERNEL_ARTIFACT="nerdbox-kernel-x86_64"; INITRD_ARTIFACT="nerdbox-initrd-x86_64" ;;
  arm64) KERNEL_ARTIFACT="nerdbox-kernel-arm64_4k"; INITRD_ARTIFACT="nerdbox-initrd-arm64" ;;
  *)     echo "Unsupported arch: ${GOARCH}" >&2; exit 1 ;;
esac

rpmDefine=(
  --define "_version ${pkgVersion}"
  --define "_origversion ${VERSION}"
  --define "_release ${PKG_RPM_RELEASE:-1}"
  --define "_kernel_artifact ${KERNEL_ARTIFACT}" --define "_initrd_artifact ${INITRD_ARTIFACT}"
)

pkgoutput="${OUTDIR}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi

set -x

# Install pre-built sbx binary
install -D -p -m 0755 /opt/sbx-bin/sbx /usr/local/bin/sbx

# Install runtime companion binaries
install -D -p -m 0755 "/opt/runtime-bin/containerd-shim-nerdbox-v1-linux-${GOARCH}" /usr/local/libexec/containerd-shim-nerdbox-v1
build-erofs /opt/erofs-src /usr/local/libexec/mkfs.erofs
install -D -p -m 0755 "/opt/runtime-bin/mkfs.ext4-linux-${GOARCH}" /usr/local/libexec/mkfs.ext4
install -D -p -m 0644 "/opt/runtime-bin/${KERNEL_ARTIFACT}" "/usr/local/libexec/${KERNEL_ARTIFACT}"
install -D -p -m 0644 "/opt/runtime-bin/${INITRD_ARTIFACT}" "/usr/local/libexec/${INITRD_ARTIFACT}"
mkdir -p /usr/local/libexec/lib
install -D -p -m 0755 "/opt/runtime-bin/libkrun-${GOARCH}.so" /usr/local/libexec/lib/libkrun.so

# Install AppArmor profile (picked up by rpmbuild)
install -D -p -m 0644 /opt/apparmor/docker-sbx-nerdbox-shim /usr/local/share/apparmor/docker-sbx-nerdbox-shim

# Install third-party license notices and license texts
install -D -p -m 0644 /opt/notices/THIRD-PARTY-NOTICES /usr/local/share/doc/docker-sbx/THIRD-PARTY-NOTICES
install -D -p -m 0644 /opt/licenses/LICENSE /usr/local/share/licenses/docker-sbx/LICENSE
install -D -p -m 0644 /opt/licenses/GPL-2.0 /usr/local/share/licenses/docker-sbx/GPL-2.0
install -D -p -m 0644 /opt/licenses/Apache-2.0 /usr/local/share/licenses/docker-sbx/Apache-2.0

rpmbuild --target $(xx-info rhel-arch) $PKG_RPM_BUILDFLAGS "${rpmDefine[@]}" /root/rpmbuild/SPECS/*.spec
mkdir -p "${pkgoutput}"
cp ./RPMS/*/*.* "${pkgoutput}"/
if [ "$(ls -A ./SRPMS)" ]; then
  cp ./SRPMS/* "${pkgoutput}"/
fi
