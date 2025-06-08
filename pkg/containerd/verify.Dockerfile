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

ARG PKG_TYPE
ARG PKG_BASE_IMAGE

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM scratch AS bin-folder
FROM scratch AS common-scripts

FROM ${PKG_BASE_IMAGE} AS verify-deb
RUN apt-get update
COPY --from=xx / /
ARG PKG_DISTRO
ARG PKG_DISTRO_ID
ARG PKG_DISTRO_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin-folder,target=/build <<EOT
  set -e
  dir=/build/${PKG_DISTRO}/${PKG_DISTRO_SUITE}/$(xx-info arch)
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

FROM ${PKG_BASE_IMAGE} AS verify-rpm
COPY --from=xx / /
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_DISTRO_ID
ARG PKG_DISTRO_SUITE
RUN --mount=type=bind,from=common-scripts,source=verify-rpm-init.sh,target=/usr/local/bin/verify-rpm-init \
  verify-rpm-init $PKG_RELEASE
ARG TARGETPLATFORM
RUN --mount=from=bin-folder,target=/build <<EOT
  set -e
  dir=/build/${PKG_DISTRO}/${PKG_DISTRO_SUITE}/$(xx-info arch)
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

FROM ${PKG_BASE_IMAGE} AS verify-static
RUN apt-get update && apt-get install -y --no-install-recommends tar
COPY --from=xx / /
ARG PKG_DISTRO
ARG PKG_DISTRO_ID
ARG PKG_DISTRO_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin-folder,target=/build <<EOT
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

FROM verify-${PKG_TYPE}
