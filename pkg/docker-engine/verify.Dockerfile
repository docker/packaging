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

ARG XX_VERSION="1.1.2"

ARG PKG_TYPE
ARG PKG_BASE_IMAGE

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM scratch AS bin-folder

FROM ${PKG_BASE_IMAGE} AS verify-deb
RUN apt-get update && apt-get install -y --no-install-recommends libdevmapper-dev
COPY --from=xx / /
ARG PKG_DISTRO
ARG PKG_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin-folder,target=/build <<EOT
  set -e
  for package in $(find /build/${PKG_DISTRO}/${PKG_SUITE}/$(xx-info arch) -type f -name 'docker-ce_[0-9]*.deb'); do
    (
      set -x
      dpkg-deb --info $package
      dpkg -i --ignore-depends=containerd.io,docker-ce-cli,iptables --force-depends $package
    )
  done
  set -x
  dockerd --version
EOT

FROM ${PKG_BASE_IMAGE} AS verify-rpm
COPY --from=xx / /
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
RUN <<EOT
  set -e
  case "$PKG_RELEASE" in
    centos9)
      dnf install -y dnf-plugins-core
      dnf config-manager --set-enabled crb
      ;;
    oraclelinux7)
      yum install -y oraclelinux-release-el7 oracle-epel-release-el7
      yum-config-manager --enable ol7_addons ol7_latest ol7_optional_latest
      ;;
    oraclelinux8)
      dnf install -y dnf-plugins-core oraclelinux-release-el8 oracle-epel-release-el8
      dnf config-manager --enable ol8_addons ol8_codeready_builder
      ;;
    oraclelinux9)
      dnf install -y dnf-plugins-core oraclelinux-release-el9 oracle-epel-release-el9
      dnf config-manager --enable ol9_addons ol9_codeready_builder
      ;;
  esac
  yum install -y device-mapper-devel
EOT
ARG TARGETPLATFORM
RUN --mount=from=bin-folder,target=/build <<EOT
  set -e
  for f in $(find /build/${PKG_DISTRO}/${PKG_SUITE}/$(xx-info arch) -type f -name 'docker-ce-[0-9]*.rpm'); do
    (
      set -x
      rpm -qilp $f
      rpm --install --nodeps $f
    )
  done
  set -x
  dockerd --version
EOT

FROM ${PKG_BASE_IMAGE} AS verify-static
RUN apt-get update && apt-get install -y --no-install-recommends tar
COPY --from=xx / /
ARG PKG_DISTRO
ARG PKG_SUITE
ARG TARGETPLATFORM
RUN --mount=from=bin-folder,target=/build <<EOT
  set -e
  for f in $(find /build/static/$(xx-info os)/$(xx-info arch) -type f); do
    (
      set -x
      tar zxvf $f -C /usr/bin --strip-components=1
    )
  done
  set -x
  dockerd --version
EOT

FROM verify-${PKG_TYPE}
