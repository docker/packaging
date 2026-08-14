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

ARG XX_VERSION="1.9.0"

ARG DISTRO_TYPE="deb"
ARG DISTRO_IMAGE="debian:bookworm"

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM scratch AS bin

FROM --platform=$BUILDPLATFORM ${DISTRO_IMAGE} AS base

FROM base AS verify-static
RUN apt-get update && apt-get install -y --no-install-recommends tar unzip
COPY --from=xx / /
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
  if [ "$(xx-info os)" = "windows" ]; then
    found=
    for package in $(find $dir -type f -name '*.zip'); do
      found=1
      (
        set -x
        unzip -l $package
        workdir=$(mktemp -d -t docker-verify.XXXXXXXXXX)
        unzip -q $package -d $workdir
        xx-verify --static $workdir/docker/docker.exe
        xx-verify --static $workdir/docker/dockerd.exe
        xx-verify --static $workdir/docker/containerd.exe
        xx-verify --static $workdir/docker/ctr.exe
        xx-verify --static $workdir/docker/containerd-shim-runhcs-v1.exe
      )
    done
    if [ -z "$found" ]; then
      echo >&2 "error: no packages found in $dir"
      exit 1
    fi
    exit 0
  fi
  for package in $(find $dir -type f -name '*.tgz'); do
    (
      set -x
      tar zxvf $package -C /usr/bin --strip-components=1
    )
  done
  set -x
  docker --version
  dockerd --version
  containerd --version
  ctr --version
  runc --version
EOT

FROM verify-${DISTRO_TYPE}
