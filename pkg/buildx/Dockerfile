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

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS base
RUN apk add --no-cache bash curl file git zip tar

FROM base AS src
WORKDIR /src
ARG APP_REPO
RUN git init . && git remote add origin "${APP_REPO}"
ARG APP_VERSION
RUN git fetch origin "${APP_VERSION}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM scratch AS build
FROM base AS binary
WORKDIR /out
ARG MODE
ARG APP_VERSION
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=from=build,target=/build <<EOL
  set -e
  BIN_EXT=$([ "$TARGETOS" = "windows" ] && echo ".exe" || true)
  if [ "$MODE" = "download" ]; then
    RELEASE_FILENAME="buildx-${APP_VERSION}.$TARGETOS-$TARGETARCH"
    if [ -n "$TARGETVARIANT" ]; then
      RELEASE_FILENAME="$RELEASE_FILENAME-$TARGETVARIANT"
    fi
    (set -x ; wget -q "https://github.com/docker/buildx/releases/download/${APP_VERSION}/${RELEASE_FILENAME}${BIN_EXT}" -qO "buildx")
  else
    cp /build/buildx${BIN_EXT} buildx
  fi
  chmod +x buildx
EOL

FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx
FROM --platform=$BUILDPLATFORM goreleaser/nfpm:v${NFPM_VERSION} AS nfpm
FROM base AS build-pkg
WORKDIR /work
COPY --from=xx / /
COPY --from=binary /out/buildx /usr/bin/buildx
ARG MODE
ARG APP_VERSION
ARG PKG_NAME
ARG PKG_TYPE
ARG PKG_RELEASE
ARG PKG_VENDOR
ARG PKG_PACKAGER
ARG PKG_OUTPUT=/build
ARG TARGETPLATFORM
RUN --mount=source=nfpm.yml,target=nfpm.yml \
    --mount=from=src,source=/src,target=/src \
    --mount=from=nfpm,source=/usr/bin/nfpm,target=/usr/bin/nfpm <<EOT
  if [ "$MODE" != "download" ]; then
    APP_VERSION="$(git -C "/src" describe --match 'v[0-9]*' --dirty='.m' --always --tags)"
  fi
  PKG_OUTPUT="${PKG_OUTPUT}/$(xx-info os)/$(xx-info arch)"
  if [ -n "$(xx-info variant)" ]; then
    PKG_OUTPUT="${PKG_OUTPUT}/$(xx-info variant)"
  fi
  mkdir -p "${PKG_OUTPUT}"
  if [ $PKG_TYPE = "static" ]; then
    workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
    mkdir -p "$workdir/${PKG_NAME}"
    echo "using static packager"
    (
      set -x
      cp /src/LICENSE /src/README.md "$workdir/${PKG_NAME}/"
    )
    if [ "$(xx-info os)" = "windows" ]; then
      (
        set -x
        cp /usr/bin/buildx "$workdir/${PKG_NAME}/docker-buildx.exe"
        cd "$workdir"
        zip -r "$PKG_OUTPUT/${PKG_NAME}_${APP_VERSION#v}.zip" ${PKG_NAME}
      )
    else
      (
        set -x
        cp /usr/bin/buildx "$workdir/${PKG_NAME}/docker-buildx"
        tar -czf "$PKG_OUTPUT/${PKG_NAME}_${APP_VERSION#v}.tgz" -C "$workdir" ${PKG_NAME}
      )
    fi
  elif [ "$(xx-info os)" = "linux" ]; then
    case $PKG_TYPE in
      apk)
        arch=$(xx-info alpine-arch);;
      deb)
        arch=$(xx-info debian-arch);;
      rpm)
        arch=$(xx-info rhel-arch);;
    esac
    (
      set -x
      ARCH="${arch}" VERSION="${APP_VERSION}" RELEASE="$PKG_RELEASE" VENDOR="${PKG_VENDOR}" PACKAGER="${PKG_PACKAGER}" nfpm package --config ./nfpm.yml --packager $PKG_TYPE --target "$PKG_OUTPUT"
    )
  else
    rm -rf "${PKG_OUTPUT}"
  fi
EOT

FROM scratch AS pkg
COPY --from=build-pkg /build /
