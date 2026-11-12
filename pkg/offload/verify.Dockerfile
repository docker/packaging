# syntax=docker/dockerfile:1

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

# Installs the built package on a clean distro image and checks the plugin it installs.

ARG XX_VERSION="1.10.0"

ARG DISTRO_TYPE="deb"
ARG DISTRO_IMAGE="debian:trixie"

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM scratch AS bin
FROM scratch AS scripts

FROM ${DISTRO_IMAGE} AS base
# The version the plugin must report, for example v0.7.48. Empty skips the version check.
ARG VERSION=""
ARG PLUGIN=/usr/libexec/docker/cli-plugins/docker-offload

FROM base AS verify-deb
COPY --from=xx / /
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG TARGETPLATFORM
ARG VERSION
ARG PLUGIN
RUN --mount=from=bin,target=/build <<EOT
  set -e
  targetplatform=$(xx-info os)_$(xx-info arch)
  if [ -n "$(xx-info variant)" ]; then
    targetplatform="${targetplatform}_$(xx-info variant)"
  fi
  dir=/build/${targetplatform}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "error: no packages found in $dir"
    exit 1
  fi
  for package in $(find $dir -type f -name '*.deb'); do
    (
      set -x
      dpkg-deb --info $package
      apt-get update
      apt-get install -y --no-install-recommends $package
    )
  done
  set -x
  test -x "$PLUGIN"
  "$PLUGIN" docker-cli-plugin-metadata
  if [ -n "$VERSION" ]; then
    "$PLUGIN" docker-cli-plugin-metadata | grep -F "\"Version\": \"$VERSION\""
  fi
EOT

FROM base AS verify-rpm
COPY --from=xx / /
ARG DISTRO_NAME
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
RUN --mount=type=bind,from=scripts,source=verify-rpm-init.sh,target=/usr/local/bin/verify-rpm-init \
  verify-rpm-init $DISTRO_NAME
ARG TARGETPLATFORM
ARG VERSION
ARG PLUGIN
RUN --mount=from=bin,target=/build <<EOT
  set -e
  targetplatform=$(xx-info os)_$(xx-info arch)
  if [ -n "$(xx-info variant)" ]; then
    targetplatform="${targetplatform}_$(xx-info variant)"
  fi
  dir=/build/${targetplatform}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "error: no packages found in $dir"
    exit 1
  fi
  for package in $(find $dir -type f -name '*.rpm' ! -name '*.src.rpm'); do
    (
      set -x
      rpm -qilp $package
      dnf install -y $package
    )
  done
  set -x
  test -x "$PLUGIN"
  "$PLUGIN" docker-cli-plugin-metadata
  if [ -n "$VERSION" ]; then
    "$PLUGIN" docker-cli-plugin-metadata | grep -F "\"Version\": \"$VERSION\""
  fi
EOT

FROM verify-${DISTRO_TYPE} AS verify
