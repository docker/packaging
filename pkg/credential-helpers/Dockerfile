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
ARG ALPINE_VERSION="3.16"
ARG OSXCROSS_VERSION="11.3-r7-debian"
ARG DEBIAN_FRONTEND="noninteractive"

# go
ARG GO_IMAGE="golang"
ARG GO_VERSION="1.18.5"
ARG GO_IMAGE_VARIANT="buster"

# pkg matrix
ARG PKG_RELEASE="debian11"
ARG PKG_TYPE="deb"
ARG PKG_DISTRO="debian"
ARG PKG_SUITE="bullseye"
ARG PKG_BASE_IMAGE="debian:bullseye"

# deb specific, see vars.mk for more details
ARG PKG_DEB_BUILDFLAGS="-b -uc"
ARG PKG_DEB_REVISION="0"
ARG PKG_DEB_EPOCH="5"

# rpm specific, see vars.mk for more details
ARG PKG_RPM_BUILDFLAGS="-bb"
ARG PKG_RPM_RELEASE="1"

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# osxcross contains the MacOSX cross toolchain for xx
FROM crazymax/osxcross:${OSXCROSS_VERSION} AS osxcross

# go base image to retrieve /usr/local/go
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go

# dummy stage for unsupported platforms
FROM --platform=$BUILDPLATFORM busybox AS builder-dummy
RUN mkdir -p /out
FROM scratch AS build-dummy
COPY --from=builder-dummy /out /out

# base stage for fetching sources and create final release
FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS base
RUN apk add --no-cache bash curl file git zip tar

FROM base AS src
WORKDIR /src
ARG CREDENTIAL_HELPERS_REPO
RUN git init . && git remote add origin "${CREDENTIAL_HELPERS_REPO}"
ARG CREDENTIAL_HELPERS_VERSION
RUN git fetch origin "${CREDENTIAL_HELPERS_VERSION}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM base AS src-tgz
RUN --mount=from=src,source=/src,target=/docker-credential-helpers \
    mkdir /out && tar -C / -zcf /out/docker-credential-helpers.tgz --exclude .git docker-credential-helpers

# deb
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-deb
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y apt-utils bash curl devscripts equivs git
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ARG PKG_RELEASE
RUN --mount=type=bind,source=internal/pkg-deb-init.sh,target=/usr/local/bin/pkg-deb-init pkg-deb-init

FROM build-base-deb AS build-deb
COPY deb /root/package/debian
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-deb-builddeps.sh,target=/usr/local/bin/pkg-deb-builddeps pkg-deb-builddeps
WORKDIR /root/package
COPY --from=src /src ./docker-credential-helpers
ARG CREDENTIAL_HELPERS_VERSION
ARG PKG_NAME
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_DEB_BUILDFLAGS
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=internal/pkg-deb-build.sh,target=/usr/local/bin/pkg-deb-build \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod \
    OUTDIR=/out pkg-deb-build

FROM build-dummy AS builder-deb-darwin
FROM build-deb AS builder-deb-linux
FROM build-dummy AS builder-deb-windows
FROM builder-deb-${TARGETOS} AS builder-deb

# rpm
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-rpm
COPY --from=xx / /
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ARG PKG_RELEASE
RUN --mount=type=bind,source=internal/pkg-rpm-init.sh,target=/usr/local/bin/pkg-rpm-init pkg-rpm-init

FROM build-base-rpm AS build-rpm
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-rpm-builddeps.sh,target=/usr/local/bin/pkg-rpm-builddeps pkg-rpm-builddeps
WORKDIR /root/rpmbuild
ARG CREDENTIAL_HELPERS_VERSION
ARG PKG_NAME
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=internal/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,from=src-tgz,source=/out/docker-credential-helpers.tgz,target=/root/rpmbuild/SOURCES/docker-credential-helpers.tgz \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/docker-credential-helpers \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod \
    OUTDIR=/out SRCDIR=/usr/local/src/docker-credential-helpers pkg-rpm-build

FROM build-dummy AS builder-rpm-darwin
FROM build-rpm AS builder-rpm-linux
FROM build-dummy AS builder-rpm-windows
FROM builder-rpm-${TARGETOS} AS builder-rpm

# static
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-static
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends clang dpkg-dev file git lld llvm make pkg-config
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV CGO_ENABLED="1"
ARG TARGETPLATFORM
RUN xx-apt-get install -y binutils gcc libc6-dev libgcc-10-dev libsecret-1-dev pkg-config

FROM build-base-static AS build-static-linux
ARG TARGETPLATFORM
ARG CREDENTIAL_HELPERS_VERSION
WORKDIR /src
RUN --mount=type=bind,from=src,source=/src,target=.,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -e
  xx-go --wrap
  make build-pass VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR=/out/docker-credential-pass
  make build-secretservice VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR=/out/docker-credential-secretservice
  xx-verify /out/docker-credential-pass/docker-credential-pass
  xx-verify /out/docker-credential-secretservice/docker-credential-secretservice
EOT

FROM build-base-static AS build-static-darwin
ARG TARGETPLATFORM
ARG CREDENTIAL_HELPERS_VERSION
WORKDIR /src
RUN --mount=type=bind,from=src,source=/src,target=.,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=bind,from=osxcross,src=/osxsdk,target=/xx-sdk <<EOT
  set -e
  xx-go --wrap
  go install std
  make build-osxkeychain VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR=/out/docker-credential-osxkeychain
  make build-pass VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR=/out/docker-credential-pass
  xx-verify /out/docker-credential-osxkeychain/docker-credential-osxkeychain
  xx-verify /out/docker-credential-pass/docker-credential-pass
EOT

FROM build-base-static AS build-static-windows
ARG TARGETPLATFORM
ARG CREDENTIAL_HELPERS_VERSION
WORKDIR /src
RUN --mount=type=bind,from=src,source=/src,target=.,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -e
  xx-go --wrap
  make build-wincred VERSION=$CREDENTIAL_HELPERS_VERSION DESTDIR=/out/docker-credential-wincred
  mv /out/docker-credential-wincred/docker-credential-wincred /out/docker-credential-wincred/docker-credential-wincred.exe
  xx-verify /out/docker-credential-wincred.exe
EOT

FROM build-static-${TARGETOS} AS build-static

FROM build-base-static AS builder-static
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends bash file zip tar
WORKDIR /build
ARG CREDENTIAL_HELPERS_VERSION
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=src,source=/src,target=/src \
    --mount=type=bind,from=build-static,source=/out,target=/build \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/src pkg-static-build

FROM builder-${PKG_TYPE} AS build-pkg

FROM scratch AS pkg
COPY --from=build-pkg /out /
