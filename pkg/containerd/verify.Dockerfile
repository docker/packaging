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

ARG DISTRO_TYPE
ARG DISTRO_IMAGE

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM scratch AS bin
FROM scratch AS scripts

FROM ${DISTRO_IMAGE} AS verify-deb
RUN apt-get update
COPY --from=xx / /
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin,target=/build <<EOT
  set -e
  dir=/build/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "warning: no packages found in $dir"
    exit 0
  fi
  for package in $(find $dir -type f -name 'containerd.io_[0-9]*.deb'); do
    (
      set -x
      dpkg-deb --info $package
      apt-get install -y --no-install-recommends $package
    )
  done
  set -x
  runc --version
  containerd --version
  containerd-shim-runc-v2 -v
EOT

FROM ${DISTRO_IMAGE} AS verify-rpm
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
  dir=/build/${DISTRO_RELEASE}/${DISTRO_SUITE}/$(xx-info arch)
  if [ ! -d "$dir" ]; then
    echo >&2 "warning: no packages found in $dir"
    exit 0
  fi
  for package in $(find $dir -type f -name 'containerd.io-[0-9]*.rpm'); do
    (
      set -x
      rpm -qilp $package
      yum install -y $package
    )
  done
  set -x
  runc --version
  containerd --version
  containerd-shim-runc-v2 -v
EOT

FROM ${DISTRO_IMAGE} AS verify-static
RUN apt-get update && apt-get install -y --no-install-recommends tar
COPY --from=xx / /
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin,target=/build <<EOT
  set -e
  dir=/build/static/$(xx-info os)/$(xx-info arch)
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
  runc --version
  containerd --version
  containerd-shim-runc-v2 -v
EOT

FROM verify-${DISTRO_TYPE}
