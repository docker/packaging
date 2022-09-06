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

ARG ALPINE_VERSION="3.16"
ARG NFPM_VERSION="2.15.1"
ARG XX_VERSION="1.1.2"
ARG MODE="download"

# pkg matrix
ARG PKG_RELEASE="debian11"
ARG PKG_TYPE="deb"
ARG PKG_DISTRO="debian"
ARG PKG_SUITE="bullseye"

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# nFPM is Not FPM - a simple deb, rpm and apk packager
FROM --platform=$BUILDPLATFORM goreleaser/nfpm:v${NFPM_VERSION} AS nfpm

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS base
COPY --from=xx / /
RUN apk add --no-cache bash curl file git zip tar

FROM base AS src
WORKDIR /src
ARG BUILDX_REPO
RUN git init . && git remote add origin "${BUILDX_REPO}"
ARG BUILDX_VERSION
RUN git fetch origin "${BUILDX_VERSION}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM scratch AS build
FROM base AS binary
WORKDIR /out
ARG MODE
ARG BUILDX_VERSION
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=from=build,target=/build <<EOL
  set -e
  BIN_EXT=$([ "$TARGETOS" = "windows" ] && echo ".exe" || true)
  if [ "$MODE" = "download" ]; then
    RELEASE_FILENAME="buildx-${BUILDX_VERSION}.$TARGETOS-$TARGETARCH"
    if [ -n "$TARGETVARIANT" ]; then
      RELEASE_FILENAME="$RELEASE_FILENAME-$TARGETVARIANT"
    fi
    (set -x ; wget -q "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/${RELEASE_FILENAME}${BIN_EXT}" -qO "buildx")
  else
    cp /build/buildx${BIN_EXT} buildx
  fi
  chmod +x buildx
  xx-verify --static buildx
EOL

FROM base AS build-pkg
WORKDIR /work
COPY --from=binary /out/buildx /usr/bin/buildx
ARG MODE
ARG BUILDX_VERSION
ARG PKG_NAME
ARG PKG_RELEASE
ARG PKG_TYPE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_VENDOR
ARG PKG_REVISION
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-build.sh,target=/usr/local/bin/pkg-build \
    --mount=type=bind,source=internal/nfpm.yml,target=nfpm.yml \
    --mount=type=bind,from=src,source=/src,target=/src \
    --mount=type=bind,from=nfpm,source=/usr/bin/nfpm,target=/usr/bin/nfpm <<EOT
  set -e
  if [ "$MODE" != "download" ]; then
    export BUILDX_VERSION="$(git -C "/src" describe --match 'v[0-9]*' --dirty='.m' --always --tags)"
  fi
  OUTDIR=/out pkg-build
EOT

FROM scratch AS pkg
COPY --from=build-pkg /out /
