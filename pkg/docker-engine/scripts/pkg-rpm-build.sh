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

: "${DISTRO_NAME=}"
: "${DISTRO_RELEASE=}"
: "${DISTRO_ID=}"
: "${DISTRO_SUITE=}"

: "${PKG_NAME=}"
: "${PKG_PACKAGER=}"
: "${PKG_VENDOR=}"

: "${PKG_RPM_RELEASE=}"

: "${SOURCE_DATE_EPOCH=}"
: "${SRCDIR=/work/src}"
: "${OUTDIR=/out}"

: "${TAGPREFIX=}"

set -e

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

for l in $(gen-ver "${SRCDIR}"); do
  export "${l?}"
done

export GO111MODULE=$(check-gomod)

xx-go --wrap
fix-cc

no_libnftables=0
case "$DISTRO_NAME" in
  rhel*)
    # The nftables-devel package is only available in RHEL CRB. For now, build
    # with tag "no_libnftables", so dockerd will exec the nft tool, and this
    # package is not required. Note that this '--define' is also defined in
    # the Dockerfile to install build dependencies.
    no_libnftables=1
    ;;
esac

rpmDefine=(
  --define "_version ${GENVER_PKG_VERSION}"
  --define "_origversion ${GENVER_VERSION}"
  --define "_release ${PKG_RPM_RELEASE:-${GENVER_RPM_RELEASE}}"
  --define "_commit ${GENVER_COMMIT_SHORT}"
  --define "_no_libnftables ${no_libnftables}"
)

pkgoutput="${OUTDIR}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)"
if [ -n "$(xx-info variant)" ]; then
  pkgoutput="${pkgoutput}/$(xx-info variant)"
fi

case "$DISTRO_NAME" in
  centos9|centos10|oraclelinux*)
    export DOCKER_BUILDTAGS="exclude_graphdriver_btrfs $DOCKER_BUILDTAGS"
    ;;
esac
if [ "$no_libnftables" -eq 1 ]; then
  export DOCKER_BUILDTAGS="no_libnftables $DOCKER_BUILDTAGS"
fi

set -x

rpmbuild --target $(xx-info rhel-arch) $PKG_RPM_BUILDFLAGS "${rpmDefine[@]}" /root/rpmbuild/SPECS/*.spec
mkdir -p "${pkgoutput}"
cp ./RPMS/*/*.* "${pkgoutput}"/
if [ "$(ls -A ./SRPMS)" ]; then
  cp ./SRPMS/* "${pkgoutput}"/
fi
