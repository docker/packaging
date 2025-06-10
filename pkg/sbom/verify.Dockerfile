# syntax=docker/dockerfile:1

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

ARG XX_VERSION="1.6.1"

ARG DISTRO_TYPE="deb"
ARG DISTRO_IMAGE="debian:bullseye"

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM scratch AS bin
FROM scratch AS scripts

FROM ${DISTRO_IMAGE} AS base

FROM base AS verify-deb
RUN apt-get update
COPY --from=xx / /
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin,target=/build <<EOT
  set -e
  targetplatform=$(xx-info os)_$(xx-info arch)
  if [ -n "$(xx-info variant)" ]; then
    targetplatform="${targetplatform}_$(xx-info variant)"
  fi
  dir=/build/${targetplatform}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "warning: no packages found in $dir"
    exit 0
  fi
  for package in $(find $dir -type f -name '*.deb'); do
    (
      set -x
      dpkg-deb --info $package
      dpkg -i $package
    )
  done
  set -x
  # FIXME: sbom cli plugin should have a version command
  /usr/libexec/docker/cli-plugins/docker-sbom docker-cli-plugin-metadata
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
RUN --mount=from=bin,target=/build <<EOT
  set -e
  targetplatform=$(xx-info os)_$(xx-info arch)
  if [ -n "$(xx-info variant)" ]; then
    targetplatform="${targetplatform}_$(xx-info variant)"
  fi
  dir=/build/${targetplatform}/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "warning: no packages found in $dir"
    exit 0
  fi
  for package in $(find $dir -type f -name '*.rpm'); do
    (
      set -x
      rpm -qilp $package
      rpm --install --nodeps $package
    )
  done
  set -x
  # FIXME: sbom cli plugin should have a version command
  /usr/libexec/docker/cli-plugins/docker-sbom docker-cli-plugin-metadata
EOT

FROM base AS verify-static
RUN apt-get update && apt-get install -y --no-install-recommends tar
COPY --from=xx / /
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin,target=/build <<EOT
  set -e
  targetplatform=$(xx-info os)_$(xx-info arch)
  if [ -n "$(xx-info variant)" ]; then
    targetplatform="${targetplatform}_$(xx-info variant)"
  fi
  dir=/build/${targetplatform}/static/$(xx-info os)/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "warning: no packages found in $dir"
    exit 0
  fi
  for package in $(find $dir -type f -name '*.tgz'); do
    (
      set -x
      tar zxvf $package -C /usr/bin --strip-components=1
    )
  done
  set -x
  # FIXME: sbom cli plugin should have a version command
  docker-sbom docker-cli-plugin-metadata
EOT

FROM verify-${DISTRO_TYPE}
