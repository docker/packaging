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
ARG DEBIAN_FRONTEND="noninteractive"

ARG GOWINRES_VERSION="v0.2.3"

# common args
ARG GO_IMAGE
ARG GO_VERSION
ARG GO_IMAGE_VARIANT
ARG PKG_RELEASE
ARG PKG_TYPE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_BASE_IMAGE

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# osxcross contains the MacOSX SDK for xx
FROM dockercore/golang-cross:xx-sdk-extras AS osxsdk

# go base image to retrieve /usr/local/go
FROM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS gocross

# src
FROM --platform=$BUILDPLATFORM alpine AS src-base
RUN apk add --no-cache bash curl file git zip tar

FROM src-base AS src
WORKDIR /src
ARG DOCKER_ENGINE_REPO
RUN git init . && git remote add origin "${DOCKER_ENGINE_REPO}.git"
ARG DOCKER_ENGINE_VERSION
RUN git fetch origin "${DOCKER_ENGINE_VERSION}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM src-base AS src-tgz
RUN --mount=from=src,source=/src,target=/engine \
    mkdir /out && tar -C / -zcf /out/engine.tgz --exclude .git engine

# deb
FROM ${PKG_BASE_IMAGE} AS builder-deb
COPY --from=xx / /
ARG DEBIAN_FRONTEND
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV DOCKER_BUILDTAGS apparmor seccomp selinux
ENV RUNC_BUILDTAGS apparmor seccomp selinux
ARG PKG_RELEASE
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils bash ca-certificates curl devscripts equivs git
RUN <<EOT
  set -e
  case "$PKG_RELEASE" in
    ubuntu2004|ubuntu2204)
      if [ "$(dpkg-divert --truename /usr/bin/man)" = "/usr/bin/man.REAL" ]; then
        rm -f /usr/bin/man
        dpkg-divert --quiet --remove --rename /usr/bin/man
      fi
      ;;
  esac
EOT
COPY deb /root/package/debian
ARG TARGETPLATFORM
RUN mk-build-deps -t "xx-apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i /root/package/debian/control
WORKDIR /root/package
ARG DOCKER_ENGINE_VERSION
ARG PKG_NAME
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_DEB_BUILDFLAGS
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-deb-build.sh,target=/usr/local/bin/pkg-deb-build \
    --mount=source=common,target=/common \
    --mount=type=bind,from=src,source=/src,target=/root/package/engine,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/root/package/engine pkg-deb-build

# rpm
FROM ${PKG_BASE_IMAGE} AS builder-rpm
COPY --from=xx / /
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV DOCKER_BUILDTAGS seccomp selinux
ENV RUNC_BUILDTAGS seccomp selinux
ARG PKG_RELEASE
RUN <<EOT
  set -e
  case "$PKG_RELEASE" in
    centos7)
      [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
      yum install -y git rpm-build rpmlint epel-release
      ;;
    centos8)
      [ -f /etc/yum.repos.d/CentOS-Stream-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Stream-Sources.repo
      [ -f /etc/yum.repos.d/CentOS-Stream-PowerTools.repo ] && sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Stream-PowerTools.repo
      rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
      dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release epel-next-release
      ;;
    centos9)
      rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
      dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release epel-next-release
      dnf config-manager --set-enabled crb
      ;;
    oraclelinux7)
      [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
      yum install -y git rpm-build rpmlint epel-release
      yum-config-manager --enable ol7_addons --enable ol7_optional_latest
      ;;
    oraclelinux8)
      dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release
      dnf config-manager --enable ol8_addons --enable ol8_codeready_builder
      ;;
    oraclelinux9)
      dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release
      dnf config-manager --enable ol9_addons --enable ol9_codeready_builder
      ;;
    fedora*)
      dnf install -y git rpm-build rpmlint dnf-plugins-core
      ;;
  esac
EOT
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN <<EOT
  set -e
  builddepCmd=""
  if command -v dnf &> /dev/null; then
    builddepCmd="setarch $(xx-info rhel-arch) dnf builddep"
  elif command -v yum-builddep &> /dev/null; then
    builddepCmd="yum-builddep --target $(xx-info rhel-arch)"
  else
    echo >&2 "unable to detect package manager"
    exit 1
  fi
  set -x
  case "$PKG_RELEASE" in
    centos8|centos9|oraclelinux*)
      $builddepCmd --define '_without_btrfs 1' -y /root/rpmbuild/SPECS/*.spec
      ;;
    *)
      $builddepCmd -y /root/rpmbuild/SPECS/*.spec
      ;;
  esac
EOT
WORKDIR /root/rpmbuild
ARG DOCKER_ENGINE_VERSION
ARG PKG_NAME
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,source=common/systemd/docker.service,target=/root/rpmbuild/SOURCES/docker.service \
    --mount=type=bind,source=common/systemd/docker.socket,target=/root/rpmbuild/SOURCES/docker.socket \
    --mount=type=bind,from=src-tgz,source=/out/engine.tgz,target=/root/rpmbuild/SOURCES/engine.tgz \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/engine \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/usr/local/src/engine pkg-rpm-build

# static
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
RUN apt-get install -y --no-install-recommends dpkg-dev clang cmake make pkg-config
ARG PKG_NAME
ARG DOCKER_CLI_VERSION
WORKDIR /build
ARG TARGETPLATFORM
RUN xx-apt-get install -y gcc libc6-dev libbtrfs-dev libdevmapper-dev libltdl-dev
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/docker/docker,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=bind,from=gowinres,source=/out/go-winres,target=/usr/bin/go-winres \
    --mount=type=tmpfs,target=/go/src/github.com/docker/docker/cli/winresources/dockerd \
    --mount=type=tmpfs,target=/go/src/github.com/docker/docker/cli/winresources/docker-proxy \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/go/src/github.com/docker/docker pkg-static-build

FROM builder-${PKG_TYPE} AS build-pkg

FROM scratch AS pkg
COPY --from=build-pkg /out /
