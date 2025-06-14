#!/usr/bin/env bash

# Copyright 2023 Docker Packaging authors
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

version="$1"
pkgVersion="$2"
pkgDistro="$3"
pkgDistroId="$4"
pkgDistroSuite="$5"
if [[ -z "$version" ]] || [[ -z "$pkgVersion" ]] || [[ -z "$pkgDistro" ]] || [[ -z "$pkgDistroId" ]] || [[ -z "$pkgDistroSuite" ]]; then
  echo "usage: ./gen-deb-changelog <version> <pkg_version> <DISTRO_RELEASE> <DISTRO_ID> <DISTRO_SUITE> [<pkg_revision> <pkg_epoch>]" >&2
  exit 1
fi
if [ ! -d "debian" ]; then
  echo "This script should be run the root package" >&2
  exit 1
fi

# Include an extra `1` in the version, in case we ever would have to re-build an
# already published release with a packaging-only change.
pkgRevision=${6:-1}

# This is a single (generally small) unsigned integer. It may be omitted, in
# which case zero is assumed. Epochs can help when the upstream version
# numbering scheme changes, but they must be used with care. You should not
# change the epoch, even in experimental, without getting consensus on
# debian-devel first.
pkgEpoch=${7:-}
pkgEpochSep=""
if [ -n "$pkgEpoch" ]; then
  pkgEpochSep=":"
fi

pkgSource="$(awk -F ': ' '$1 == "Source" { print $2; exit }' debian/control)"
pkgMaintainer="$(awk -F ': ' '$1 == "Maintainer" { print $2; exit }' debian/control)"
pkgDate="$(date --rfc-2822)"

# Generate changelog. The version/name of the generated packages are based on this.
#
# Resulting packages are formatted as;
#
# - name of the package (e.g., "docker-ce")
# - version (e.g., "23.0.0~beta.0")
# - pkgRevision (usually "-0", see above), which allows updating packages with
#   packaging-only changes (without a corresponding release of the software
#   that's packaged).
# - distro (e.g., "ubuntu")
# - VERSION_ID (e.g. "22.04" or "11") this must be "sortable" to make sure that
#   packages are upgraded when upgrading to a newer distro version ("codename"
#   cannot be used for this, as they're not sorted)
# - SUITE ("codename"), e.g. "jammy" or "bullseye". This is mostly for convenience,
#   because some places refer to distro versions by codename, others by version.
#   we prefix the codename with a tilde (~), which effectively excludes it from
#   version comparison.
#
# Note that while the `${EPOCH}${EPOCH_SEP}` is part of the version, it is not
# included in the package's *filename*. (And if you're wondering: we needed the
# EPOCH because of our use of CalVer, which made version comparing not work in
# some cases).
#
# Examples:
#
# docker-ce_23.0.0~beta.0-1~debian.11~bullseye_amd64.deb
# docker-ce_23.0.0~beta.0-1~ubuntu.22.04~jammy_amd64.deb

if [[ -f "debian/changelog" ]] && [[ "${version}" != "v${pkgVersion}" ]]; then
  cp "debian/changelog" "debian/changelog.or"
fi
if [[ ! -f "debian/changelog" ]] || [[ "${version}" != "v${pkgVersion}" ]]; then
  cat > "debian/changelog" <<-EOF
$pkgSource (${pkgEpoch}${pkgEpochSep}${pkgVersion}-${pkgRevision}~${pkgDistro}.${pkgDistroId}~${pkgDistroSuite}) $pkgDistroSuite; urgency=low
  * Version: $version
 -- $pkgMaintainer  $pkgDate
EOF
  # The space above at the start of the line for the pkgMaintainer is very important
fi
if [ -f "debian/changelog.or" ]; then
  cat "debian/changelog.or" >> "debian/changelog"
  rm "debian/changelog.or"
fi
