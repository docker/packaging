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

# specific to docker-engine
ARG GOWINRES_VERSION="v0.2.3"

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

# osxcross contains the MacOSX SDK for xx
FROM dockercore/golang-cross:xx-sdk-extras AS osxsdk

# go base image to retrieve /usr/local/go
FROM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go

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
ARG DOCKER_ENGINE_REPO
RUN git init . && git remote add origin "${DOCKER_ENGINE_REPO}"
ARG DOCKER_ENGINE_VERSION
RUN git fetch origin "${DOCKER_ENGINE_VERSION}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM base AS src-tgz
RUN --mount=from=src,source=/src,target=/engine \
    mkdir /out && tar -C / -zcf /out/engine.tgz --exclude .git engine

# deb
FROM ${PKG_BASE_IMAGE} AS build-base-deb
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y bash curl devscripts equivs git
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV DOCKER_BUILDTAGS apparmor seccomp selinux
ENV RUNC_BUILDTAGS apparmor seccomp selinux
ARG PKG_RELEASE
RUN --mount=type=bind,source=internal/pkg-deb-init.sh,target=/usr/local/bin/pkg-deb-init pkg-deb-init

FROM build-base-deb AS build-deb
COPY deb /root/package/debian
ARG TARGETPLATFORM
ARG DEBIAN_FRONTEND
ARG PKG_RELEASE
RUN --mount=type=bind,source=internal/pkg-deb-builddeps.sh,target=/usr/local/bin/pkg-deb-builddeps pkg-deb-builddeps
WORKDIR /root/package
COPY --from=src /src ./engine
ARG DOCKER_ENGINE_VERSION
ARG PKG_NAME
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_DEB_BUILDFLAGS
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=internal/pkg-deb-build.sh,target=/usr/local/bin/pkg-deb-build \
    --mount=source=common,target=/common \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=./engine pkg-deb-build

FROM build-dummy AS builder-deb-darwin
FROM build-deb AS builder-deb-linux
FROM build-dummy AS builder-deb-windows
FROM builder-deb-${TARGETOS} AS builder-deb

# rpm
FROM ${PKG_BASE_IMAGE} AS build-base-rpm
COPY --from=xx / /
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV DOCKER_BUILDTAGS seccomp selinux
ENV RUNC_BUILDTAGS seccomp selinux
ARG PKG_RELEASE
RUN --mount=type=bind,source=internal/pkg-rpm-init.sh,target=/usr/local/bin/pkg-rpm-init pkg-rpm-init

FROM build-base-rpm AS build-rpm
COPY rpm /root/rpmbuild/SPECS
ARG PKG_RELEASE
ARG TARGETPLATFORM
RUN --mount=type=bind,source=internal/pkg-rpm-builddeps.sh,target=/usr/local/bin/pkg-rpm-builddeps pkg-rpm-builddeps
WORKDIR /root/rpmbuild
COPY --from=src-tgz /out/engine.tgz ./SOURCES/
ARG DOCKER_ENGINE_VERSION
ARG PKG_NAME
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=internal/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,source=common/systemd/docker.service,target=/root/rpmbuild/SOURCES/docker.service \
    --mount=type=bind,source=common/systemd/docker.socket,target=/root/rpmbuild/SOURCES/docker.socket \
    --mount=type=bind,from=src-tgz,source=/out/engine.tgz,target=/root/rpmbuild/SOURCES/engine.tgz \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/engine \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/usr/local/src/engine pkg-rpm-build

FROM build-dummy AS builder-rpm-darwin
FROM build-rpm AS builder-rpm-linux
FROM build-dummy AS builder-rpm-windows
FROM builder-rpm-${TARGETOS} AS builder-rpm

# static
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS gocross
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-static
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates file git zip tar
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV CGO_ENABLED="1"
ENV GO111MODULE="off"

FROM build-base-static AS gowinres
ARG GOWINRES_VERSION
RUN --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    GOBIN=/out GO111MODULE=on go install "github.com/tc-hib/go-winres@${GOWINRES_VERSION}"

FROM build-base-static AS builder-static
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends dpkg-dev clang cmake make pkg-config
ARG PKG_NAME
ARG DOCKER_CLI_VERSION
WORKDIR /build
ARG TARGETPLATFORM
RUN xx-apt-get install -y gcc libc6-dev libbtrfs-dev libdevmapper-dev libltdl-dev
RUN --mount=type=bind,source=internal/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/docker/docker,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=bind,from=gowinres,source=/out/go-winres,target=/usr/bin/go-winres \
    --mount=type=tmpfs,target=/go/src/github.com/docker/docker/cli/winresources/dockerd \
    --mount=type=tmpfs,target=/go/src/github.com/docker/docker/cli/winresources/docker-proxy \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/go/src/github.com/docker/docker pkg-static-build

FROM builder-${PKG_TYPE} AS build-pkg

FROM scratch AS pkg
COPY --from=build-pkg /out /
