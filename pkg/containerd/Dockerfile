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
ARG GO_IMAGE_VARIANT="buster"

# pkg matrix
ARG PKG_RELEASE="debian11"
ARG PKG_TYPE="deb"
ARG PKG_DISTRO="debian"
ARG PKG_SUITE="bullseye"
ARG PKG_BASE_IMAGE="debian:bullseye"

# deb specific
ARG PKG_DEB_EPOCH="5"
ARG PKG_DEB_REVISION="0"

# rpm specific
ARG PKG_RPM_RELEASE="1"

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# go base image to retrieve /usr/local/go
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go

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
RUN git init . && git remote add origin "${RUNC_REPO}"
RUN --mount=from=src,source=/src,target=/containerd \
    git fetch origin "$(cat /containerd/script/setup/runc-version)" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM base AS runc-src-tgz
RUN --mount=from=runc-src,source=/src,target=/runc \
    mkdir /out && tar -C / -zcf /out/runc.tgz --exclude .git runc

# deb
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-deb
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
RUN mk-build-deps -t "xx-apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i /root/package/debian/control
WORKDIR /root/package
COPY --from=src /src ./containerd
ARG CONTAINERD_VERSION
ARG PKG_NAME
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=source=internal,target=/internal,rw \
    --mount=type=bind,from=runc-src,source=/src,target=/go/src/github.com/opencontainers/runc,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -e
  mkdir -p /out
  if [ "$(xx-info arch)" != "$(TARGETPLATFORM= xx-info arch)" ]; then
    echo "$(xx-info arch) architecture is not supported"
    exit 0
  fi
  mkdir -p $GOPATH/src/github.com/containerd
  ln -snf /root/package/containerd $GOPATH/src/github.com/containerd/containerd
  sed 's#/usr/local/bin/containerd#/usr/bin/containerd#g' $GOPATH/src/github.com/containerd/containerd/containerd.service > /internal/containerd.service
  export GO_SRC_PATH=$GOPATH/src/github.com/containerd/containerd
  export CONTAINERD_REVISION=$(git --git-dir ./containerd/.git rev-parse HEAD)
  xx-go --wrap
  set -x
  chmod -x debian/compat debian/control debian/copyright debian/manpages
  dpkg-buildpackage -us -uc
  pkgoutput="/out/${PKG_DISTRO}/${PKG_SUITE}/$(xx-info arch)"
  if [ -n "$(xx-info variant)" ]; then
    pkgoutput="${pkgoutput}/$(xx-info variant)"
  fi
  mkdir -p "${pkgoutput}"
  cp /root/${PKG_NAME}* ${pkgoutput}/
EOT

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
COPY --from=go-md2man /go/bin/go-md2man $GOPATH/bin/go-md2man
ARG PKG_RELEASE
RUN <<EOT
  case "$PKG_RELEASE" in
    centos7)
      [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
      yum install -y git rpm-build rpmlint
      ;;
    centos8)
      [ -f /etc/yum.repos.d/CentOS-Stream-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Stream-Sources.repo
      [ -f /etc/yum.repos.d/CentOS-Stream-PowerTools.repo ] && sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Stream-PowerTools.repo
      rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
      dnf install -y git rpm-build rpmlint dnf-plugins-core
      ;;
    centos9)
      rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
      dnf install -y git rpm-build rpmlint dnf-plugins-core
      dnf config-manager --set-enabled crb
      ;;
    oraclelinux7)
      [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
      yum install -y git rpm-build rpmlint
      yum-config-manager --enable ol7_addons --enable ol7_optional_latest
      ;;
    oraclelinux8)
      dnf install -y git rpm-build rpmlint dnf-plugins-core
      dnf config-manager --enable ol8_addons
      ;;
    oraclelinux9)
      dnf install -y git rpm-build rpmlint dnf-plugins-core
      dnf config-manager --enable ol9_addons
      ;;
    fedora*)
      dnf install -y git rpm-build rpmlint dnf-plugins-core
      ;;
  esac
EOT

FROM build-base-rpm AS build-rpm
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN <<EOT
  set -e
  echo "%_topdir    /root/rpmbuild" > /root/.rpmmacros
  case "$PKG_RELEASE" in
    centos7|oraclelinux7)
      yum-builddep -y /root/rpmbuild/SPECS/*.spec
      ;;
    *)
      dnf builddep -y /root/rpmbuild/SPECS/*.spec
      ;;
  esac
EOT
WORKDIR /root/rpmbuild
COPY --from=src-tgz /out/containerd.tgz ./SOURCES/
COPY --from=runc-src-tgz /out/runc.tgz ./SOURCES/
ARG CONTAINERD_VERSION
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=source=internal,target=/internal,rw \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/containerd,rw \
    --mount=type=bind,from=runc-src,source=/src,target=/go/src/github.com/opencontainers/runc,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -e
  mkdir -p /out
  if [ "$(xx-info arch)" != "$(TARGETPLATFORM= xx-info arch)" ]; then
    echo "$(xx-info arch) architecture is not supported"
    exit 0
  fi
  mkdir -p $GOPATH/src/github.com/containerd
  ln -snf /usr/local/src/containerd $GOPATH/src/github.com/containerd/containerd
  sed 's#/usr/local/bin/containerd#/usr/bin/containerd#g' /usr/local/src/containerd/containerd.service > /internal/containerd.service
  cp /internal/* ./SOURCES/
  rpmVersion=${CONTAINERD_VERSION#v}
  rpmVersion=$(echo $rpmVersion | sed "s/-/~/")
  xx-go --wrap
  set -x
  rpmbuild -ba \
    --define "_version ${rpmVersion}" \
    --define "_origversion ${CONTAINERD_VERSION#v}" \
    --define "_release $PKG_RPM_RELEASE" \
    --define "_commit $(git --git-dir /usr/local/src/containerd/.git rev-parse HEAD)" \
    /root/rpmbuild/SPECS/*.spec
  pkgoutput="/out/${PKG_DISTRO}/${PKG_SUITE}/$(xx-info arch)"
  if [ -n "$(xx-info variant)" ]; then
    pkgoutput="${pkgoutput}/$(xx-info variant)"
  fi
  mkdir -p "${pkgoutput}"
  cp ./RPMS/*/*.* ./SRPMS/* ${pkgoutput}/
EOT

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
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -ex
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
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -ex
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
RUN --mount=type=bind,from=src,source=/src,target=/src \
    --mount=type=bind,from=runc-src,source=/src,target=/runc-src \
    --mount=type=bind,from=build-static,source=/out,target=/build <<EOT
  set -e
  pkgoutput="/out/static/$(xx-info os)/$(xx-info arch)"
  if [ -n "$(xx-info variant)" ]; then
    pkgoutput="${pkgoutput}/$(xx-info variant)"
  fi
  mkdir -p "${pkgoutput}"
  for pkgname in *; do
    workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
    mkdir -p "$workdir/${pkgname}"
    (
      set -x
      cp ${pkgname}/* /src/LICENSE /src/README.md "$workdir/${pkgname}/"
      cp /runc-src/LICENSE "$workdir/${pkgname}/runc.LICENSE"
      cp /runc-src/README.md "$workdir/${pkgname}/runc.README.md"
    )
    if [ "$(xx-info os)" = "windows" ]; then
      (set -x ; cd "$workdir" ; zip -r "${pkgoutput}/${pkgname}_${CONTAINERD_VERSION#v}.zip" ${pkgname})
    else
      (set -x ; tar -czf "${pkgoutput}/${pkgname}_${CONTAINERD_VERSION#v}.tgz" -C "$workdir" ${pkgname})
    fi
  done
EOT

FROM builder-${PKG_TYPE} AS build-pkg

FROM scratch AS pkg
COPY --from=build-pkg /out /
