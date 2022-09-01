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

# osxcross contains the MacOSX SDK for xx
FROM dockercore/golang-cross:xx-sdk-extras AS osxsdk

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
ARG DOCKER_CLI_REPO
RUN git init . && git remote add origin "${DOCKER_CLI_REPO}"
ARG DOCKER_CLI_VERSION
RUN git fetch origin "${DOCKER_CLI_VERSION}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM base AS src-tgz
RUN --mount=from=src,source=/src,target=/cli \
    mkdir /out && tar -C / -zcf /out/cli.tgz --exclude .git cli

# deb
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-deb
COPY --from=xx / /
ARG DEBIAN_FRONTEND="noninteractive"
RUN --mount=type=cache,sharing=locked,id=build-base-deb-aptlib,target=/var/lib/apt \
    --mount=type=cache,sharing=locked,id=build-base-deb-aptcache,target=/var/cache/apt \
    apt-get update && apt-get install -y bash curl devscripts equivs git
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ARG PKG_RELEASE
RUN <<EOT
  case "$PKG_RELEASE" in
    ubuntu2004|ubuntu2204)
      if [ "$(dpkg-divert --truename /usr/bin/man)" = "/usr/bin/man.REAL" ]; then
        rm -f /usr/bin/man
        dpkg-divert --quiet --remove --rename /usr/bin/man
      fi
      ;;
  esac
EOT

FROM build-base-deb AS build-deb
COPY deb /root/package/debian
ARG TARGETPLATFORM
RUN --mount=type=cache,sharing=locked,id=build-deb-aptlib,target=/var/lib/apt \
    --mount=type=cache,sharing=locked,id=build-deb-aptcache,target=/var/cache/apt \
    mk-build-deps -t "xx-apt-get -o Debug::pkgProblemResolver=yes -y" -i /root/package/debian/control
WORKDIR /root/package
COPY --from=src /src ./cli
ARG DOCKER_CLI_VERSION
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -e
  mkdir -p /out
  if [ "$(xx-info arch)" != "$(TARGETPLATFORM= xx-info arch)" ]; then
    echo "$(xx-info arch) architecture is not supported"
    exit 0
  fi
  export DOCKER_CLI_REVISION=$(git -C ./cli rev-parse HEAD)
  debVersion=${DOCKER_CLI_VERSION#v}
  debVersion=$(echo $debVersion | sed "s/-/~/")
  cat > "debian/changelog" <<-EOF
docker-ce-cli (${PKG_DEB_EPOCH}$([ -n "$PKG_DEB_EPOCH" ] && echo ":")${debVersion}-${PKG_DEB_REVISION}) $PKG_SUITE; urgency=low
  * Version: $DOCKER_CLI_VERSION
 -- $(awk -F ': ' '$1 == "Maintainer" { print $2; exit }' debian/control)  $(date --rfc-2822)
EOF
  xx-go --wrap
  set -x
  chmod -x debian/compat debian/control debian/docs
  dpkg-buildpackage -us -uc -a$(xx-info debian-arch) -Pcross,nocheck
  pkgoutput="/out/${PKG_DISTRO}/${PKG_SUITE}/$(xx-info arch)"
  if [ -n "$(xx-info variant)" ]; then
    pkgoutput="${pkgoutput}/$(xx-info variant)"
  fi
  mkdir -p "${pkgoutput}"
  cp /root/docker-* ${pkgoutput}/
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
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ARG PKG_RELEASE
RUN --mount=type=cache,sharing=locked,id=build-base-rpm-dnfcache,target=/var/cache/dnf \
    --mount=type=cache,sharing=locked,id=build-base-rpm-yumcache,target=/var/cache/yum <<EOT
  case "$PKG_RELEASE" in
    centos7|oraclelinux7)
      [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
      yum install -y rpm-build rpmlint
      ;;
    centos8)
      [ -f /etc/yum.repos.d/CentOS-Stream-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Stream-Sources.repo
      [ -f /etc/yum.repos.d/CentOS-Stream-PowerTools.repo ] && sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Stream-PowerTools.repo
      rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
      dnf install -y rpm-build rpmlint dnf-plugins-core
      ;;
    centos9)
      rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
      dnf install -y rpm-build rpmlint dnf-plugins-core
      dnf config-manager --set-enabled crb
      ;;
    fedora*|oraclelinux8|oraclelinux9)
      dnf install -y rpm-build rpmlint dnf-plugins-core
      ;;
  esac
EOT

FROM build-base-rpm AS build-rpm
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN --mount=type=cache,sharing=locked,id=build-rpm-dnfcache,target=/var/cache/dnf \
    --mount=type=cache,sharing=locked,id=build-rpm-yumcache,target=/var/cache/yum <<EOT
  set -e
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
COPY --from=src-tgz /out/cli.tgz ./SOURCES/
ARG DOCKER_CLI_VERSION
ARG PKG_RELEASE
ARG PKG_DISTRO
ARG PKG_SUITE
ARG PKG_PACKAGER
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/cli \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -e
  mkdir -p /out
  if [ "$(xx-info arch)" != "$(TARGETPLATFORM= xx-info arch)" ]; then
    echo "$(xx-info arch) architecture is not supported"
    exit 0
  fi
  rpmVersion=${DOCKER_CLI_VERSION#v}
  rpmVersion=$(echo $rpmVersion | sed "s/-/~/")
  xx-go --wrap
  set -x
  rpmbuild -ba \
    --define "_version ${rpmVersion}" \
    --define "_origversion ${DOCKER_CLI_VERSION#v}" \
    --define "_release $PKG_RPM_RELEASE" \
    --define "_commit $(git -C /usr/local/src/cli rev-parse HEAD)" \
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
RUN --mount=type=cache,sharing=locked,id=build-base-static-aptlib,target=/var/lib/apt \
    --mount=type=cache,sharing=locked,id=build-base-static-aptcache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends clang dpkg-dev file git lld llvm pkg-config
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV CGO_ENABLED="1"
ARG TARGETPLATFORM
RUN xx-apt-get install -y binutils gcc libc6-dev libgcc-10-dev pkg-config

FROM build-base-static AS build-static
ARG TARGETPLATFORM
ARG DOCKER_CLI_VERSION
ARG GO_LINKMODE=static
ARG GO_BUILDTAGS
ARG GO_STRIP
ARG CGO_ENABLED
WORKDIR /go/src/github.com/docker/cli
RUN --mount=type=bind,from=src,source=/src,target=.,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=from=osxsdk,target=/xx-sdk,src=/xx-sdk \
    --mount=type=tmpfs,target=cli/winresources \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -ex
  xx-go --wrap
  TARGET=/out ./scripts/build/binary
  [ -L "/out/docker" ] && rm -f /out/docker && mv /out/docker-* /out/docker
  xx-verify --static /out/docker
EOT

FROM build-base-static AS builder-static
ARG DEBIAN_FRONTEND
RUN --mount=type=cache,sharing=locked,id=build-static-aptlib,target=/var/lib/apt \
    --mount=type=cache,sharing=locked,id=build-static-aptcache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends bash file zip tar
WORKDIR /build
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG DOCKER_CLI_VERSION
RUN --mount=type=bind,from=src,source=/src,target=/src \
    --mount=type=bind,from=build-static,source=/out,target=/build <<EOT
  set -e
  pkgoutput="/out/$(xx-info os)/static/$(xx-info arch)"
  if [ -n "$(xx-info variant)" ]; then
    pkgoutput="${pkgoutput}/$(xx-info variant)"
  fi
  mkdir -p "${pkgoutput}"
  ls -al
  for f in *; do
    pkgname=${f%.*}
    workdir=$(mktemp -d -t docker-packaging.XXXXXXXXXX)
    mkdir -p "$workdir/${pkgname}"
    (
      set -x
      cp ${f} /src/LICENSE /src/README.md "$workdir/${pkgname}/"
    )
    if [ "$(xx-info os)" = "windows" ]; then
      (
        set -x
        cd "$workdir"
        zip -r "${pkgoutput}/${pkgname}_${DOCKER_CLI_VERSION#v}.zip" ${pkgname}
      )
    else
      (
        set -x
        tar -czf "${pkgoutput}/${pkgname}_${DOCKER_CLI_VERSION#v}.tgz" -C "$workdir" ${pkgname}
      )
    fi
  done
EOT

FROM builder-${PKG_TYPE} AS build-pkg

FROM scratch AS pkg
COPY --from=build-pkg /out /
