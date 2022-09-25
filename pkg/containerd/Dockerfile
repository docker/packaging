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
ARG DEBIAN_FRONTEND="noninteractive"

ARG MD2MAN_VERSION="v2.0.1"
ARG RUNC_REPO="https://github.com/opencontainers/runc.git"

# go
ARG GO_IMAGE="golang"
ARG GO_VERSION="1.18.5"
ARG GO_IMAGE_VARIANT="bullseye"

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

# go base image to retrieve /usr/local/go
FROM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go

# md2man
FROM go AS go-md2man
ARG GOPROXY="direct"
ARG GO111MODULE="on"
ARG MD2MAN_VERSION
RUN go install github.com/cpuguy83/go-md2man/v2@${MD2MAN_VERSION}

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
ARG CONTAINERD_REPO
RUN git init . && git remote add origin "${CONTAINERD_REPO}"
ARG CONTAINERD_VERSION
RUN git fetch origin "${CONTAINERD_VERSION}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM base AS src-tgz
RUN --mount=from=src,source=/src,target=/containerd \
    mkdir /out && tar -C / -zcf /out/containerd.tgz --exclude .git containerd

FROM base AS runc-src
WORKDIR /src
ARG RUNC_REPO
ARG RUNC_VERSION
RUN git init . && git remote add origin "${RUNC_REPO}"
RUN --mount=from=src,source=/src,target=/containerd <<EOT
  [ -z "$RUNC_VERSION" ] && RUNC_VERSION=$(cat /containerd/script/setup/runc-version)
  git fetch origin "$RUNC_VERSION" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD
EOT

FROM base AS runc-src-tgz
RUN --mount=from=runc-src,source=/src,target=/runc \
    mkdir /out && tar -C / -zcf /out/runc.tgz --exclude .git runc

# deb
FROM ${PKG_BASE_IMAGE} AS build-base-deb
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y apt-utils bash ca-certificates curl devscripts equivs git lsb-release
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
COPY --from=go-md2man /go/bin/go-md2man $GOPATH/bin/go-md2man
ARG PKG_RELEASE

FROM build-base-deb AS build-deb
COPY deb /root/package/debian
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-deb-builddeps.sh,target=/usr/local/bin/pkg-deb-builddeps pkg-deb-builddeps
WORKDIR /root/package
ARG CONTAINERD_VERSION
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
    --mount=type=bind,source=common,target=/common,rw \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/containerd/containerd,rw \
    --mount=type=bind,from=runc-src,source=/src,target=/go/src/github.com/opencontainers/runc,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/go/src/github.com/containerd/containerd pkg-deb-build

FROM build-dummy AS builder-deb-darwin
FROM build-deb AS builder-deb-linux
FROM build-dummy AS builder-deb-windows
FROM builder-deb-${TARGETOS} AS builder-deb

# rpm
FROM ${PKG_BASE_IMAGE} AS build-base-rpm
COPY --from=xx / /
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
COPY --from=go-md2man /go/bin/go-md2man $GOPATH/bin/go-md2man
ARG PKG_RELEASE
RUN --mount=type=bind,source=internal/pkg-rpm-init.sh,target=/usr/local/bin/pkg-rpm-init pkg-rpm-init

FROM build-base-rpm AS build-rpm
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-rpm-builddeps.sh,target=/usr/local/bin/pkg-rpm-builddeps pkg-rpm-builddeps
WORKDIR /root/rpmbuild
ARG CONTAINERD_VERSION
ARG PKG_NAME
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=internal/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,source=common/containerd.toml,target=/root/rpmbuild/SOURCES/containerd.toml \
    --mount=type=bind,from=src-tgz,source=/out/containerd.tgz,target=/root/rpmbuild/SOURCES/containerd.tgz \
    --mount=type=bind,from=runc-src-tgz,source=/out/runc.tgz,target=/root/rpmbuild/SOURCES/runc.tgz \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/containerd/containerd,rw \
    --mount=type=bind,from=runc-src,source=/src,target=/go/src/github.com/opencontainers/runc,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/go/src/github.com/containerd/containerd pkg-rpm-build

FROM build-dummy AS builder-rpm-darwin
FROM build-rpm AS builder-rpm-linux
FROM build-dummy AS builder-rpm-windows
FROM builder-rpm-${TARGETOS} AS builder-rpm

# static
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS gocross
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-static
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates clang dpkg-dev file git llvm make pkg-config
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GO111MODULE="off"
ENV CGO_ENABLED="1"
ARG TARGETPLATFORM
RUN xx-apt-get install -y binutils dpkg-dev g++ gcc libbtrfs-dev libseccomp-dev libsecret-1-dev pkg-config

FROM build-base-static AS build-static
ARG TARGETPLATFORM
ARG DOCKER_CLI_VERSION
ARG CGO_ENABLED
WORKDIR /go/src/github.com/containerd/containerd
RUN --mount=type=bind,from=src,source=/src,target=.,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw <<EOT
  set -ex
  XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple
  xx-go --wrap
  mkdir -p /out/containerd
  export CC=$(xx-info)-gcc
  make STATIC=1 bin/containerd
  make STATIC=1 bin/containerd-shim-runc-v2
  make STATIC=1 bin/ctr
  xx-verify --static bin/containerd-shim-runc-v2
  xx-verify --static bin/containerd
  xx-verify --static bin/ctr
  mv bin/* /out/containerd
EOT
WORKDIR /go/src/github.com/opencontainers/runc
# FIXME: should be built using clang but needs https://github.com/opencontainers/runc/pull/3465
RUN --mount=type=bind,from=runc-src,source=/src,target=.,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw <<EOT
  set -ex
  XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple
  xx-go --wrap
  make static
  xx-verify --static runc
  mv runc /out/containerd/
EOT

FROM build-base-static AS builder-static
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends bash file zip tar
WORKDIR /build
ARG CONTAINERD_VERSION
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=src,source=/src,target=/src \
    --mount=type=bind,from=runc-src,source=/src,target=/runc-src \
    --mount=type=bind,from=build-static,source=/out,target=/build \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/src RUNC_SRCDIR=/runc-src pkg-static-build

FROM builder-${PKG_TYPE} AS build-pkg

FROM scratch AS pkg
COPY --from=build-pkg /out /
