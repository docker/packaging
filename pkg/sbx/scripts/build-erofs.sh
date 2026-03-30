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

# Build mkfs.erofs from a source checkout.
#
# Usage: build-erofs <srcdir> <output-binary>
#
# Installs distro-appropriate build dependencies, then runs
# autogen / configure / make inside a temporary copy of <srcdir>.

set -e

SRCDIR="${1:?usage: build-erofs <srcdir> <output-binary>}"
OUTBIN="${2:?usage: build-erofs <srcdir> <output-binary>}"

# Install build dependencies based on the package manager available.
if command -v apt-get &>/dev/null; then
  apt-get update -qq
  apt-get install -y --no-install-recommends \
    autoconf automake autotools-dev libtool make pkg-config \
    gcc libc6-dev \
    liblz4-dev libzstd-dev zlib1g-dev
elif command -v dnf &>/dev/null; then
  dnf install -y \
    autoconf automake libtool make pkgconfig \
    gcc \
    lz4-devel libzstd-devel zlib-devel
elif command -v yum &>/dev/null; then
  yum install -y \
    autoconf automake libtool make pkgconfig \
    gcc \
    lz4-devel libzstd-devel zlib-devel
else
  echo >&2 "error: unsupported distro — no apt-get, dnf, or yum found"
  exit 1
fi

# Build in a temporary directory so the bind-mounted source stays read-only.
BUILDDIR="$(mktemp -d)"
cp -a "${SRCDIR}/." "${BUILDDIR}/"
cd "${BUILDDIR}"

./autogen.sh
./configure \
    --disable-silent-rules \
    --enable-lz4 \
    --disable-lzma \
    --without-selinux \
    --without-uuid \
    --without-openssl \
    --disable-fuse \
    --disable-debug \
    --disable-static \
    --disable-dependency-tracking

make -j "$(nproc)"

install -D -p -m 0755 mkfs/mkfs.erofs "${OUTBIN}"
rm -rf "${BUILDDIR}"
