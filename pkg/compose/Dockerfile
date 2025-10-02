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

ARG XX_VERSION="1.7.0"
ARG DEBIAN_FRONTEND="noninteractive"

ARG DISTRO_NAME="debian12"
ARG DISTRO_TYPE="deb"
ARG DISTRO_RELEASE="debian"
ARG DISTRO_SUITE="bookworm"
ARG DISTRO_ID="12"
ARG DISTRO_IMAGE="debian:bookworm"

ARG PKG_NAME="docker-compose-plugin"
ARG PKG_REPO="https://github.com/docker/compose.git"
ARG PKG_REF="main"

ARG GO_IMAGE="golang"
ARG GO_VERSION="1.23.12"
ARG GO_IMAGE_VARIANT="bookworm"

# stage used as named context that mounts hack/scripts
# see pkg target in docker-bake.hcl
FROM scratch AS scripts

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
ARG PKG_REPO
RUN git init . && git remote add origin "${PKG_REPO}"
ARG PKG_REF
RUN git fetch origin "${PKG_REF}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM src-base AS src-tgz
RUN --mount=from=src,source=/src,target=/compose \
    mkdir /out && tar -C / -zcf /out/compose.tgz --exclude .git compose

# metadata
FROM src-base AS metadata-builder
ARG PKG_REPO
ARG PKG_REF
ARG NIGHTLY_BUILD
RUN --mount=type=bind,from=scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=src,source=/src,target=/src <<EOT
  set -e
  mkdir -p /out
  for l in $(gen-ver "/src"); do
    export "${l?}"
  done
  cat > "/out/metadata.env" <<-EOF
REPO=${PKG_REPO%.*}
REF=${PKG_REF}
VERSION=${GENVER_VERSION}
COMMIT=${GENVER_COMMIT}
EOF
EOT

FROM scratch AS metadata
COPY --from=metadata-builder /out /

# deb
FROM ${DISTRO_IMAGE} AS builder-deb
COPY --from=xx / /
ARG DEBIAN_FRONTEND
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"
ENV GO111MODULE="on"
ENV CGO_ENABLED="0"
ARG DISTRO_NAME
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils bash ca-certificates curl devscripts equivs git
COPY deb /root/package/debian
ARG TARGETPLATFORM
RUN mk-build-deps -t "xx-apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i /root/package/debian/control
WORKDIR /root/package
ARG NIGHTLY_BUILD
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG PKG_NAME
ARG PKG_REF
ARG PKG_PACKAGER
ARG PKG_DEB_BUILDFLAGS
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-deb-build.sh,target=/usr/local/bin/pkg-deb-build \
    --mount=type=bind,from=scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=scripts,source=gen-deb-changelog.sh,target=/usr/local/bin/gen-deb-changelog \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=src,source=/src,target=/root/package/compose,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=./compose pkg-deb-build

# rpm
FROM ${DISTRO_IMAGE} AS builder-rpm
COPY --from=xx / /
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"
ENV GO111MODULE="on"
ENV CGO_ENABLED="0"
ARG DISTRO_NAME
RUN --mount=type=bind,from=scripts,source=rpm-init.sh,target=/usr/local/bin/rpm-init \
    --mount=type=secret,id=RH_USER,env=RH_USER \
    --mount=type=secret,id=RH_PASS,env=RH_PASS \
    rpm-init $DISTRO_NAME
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN --mount=type=bind,from=scripts,source=rpm-builddep.sh,target=/usr/local/bin/rpm-builddep \
    rpm-builddep $(xx-info rhel-arch) /root/rpmbuild/SPECS
WORKDIR /root/rpmbuild
ARG NIGHTLY_BUILD
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG PKG_NAME
ARG PKG_REF
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,from=scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=src-tgz,source=/out/compose.tgz,target=/root/rpmbuild/SOURCES/compose.tgz \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/compose \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/usr/local/src/compose pkg-rpm-build

# static
FROM --platform=$BUILDPLATFORM ${DISTRO_IMAGE} AS builder-static-nosdk
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates file git zip tar \
  dpkg-dev clang lld llvm make pkg-config
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"
ENV GO111MODULE="on"
ENV CGO_ENABLED="0"
ARG PKG_NAME
ARG PKG_REF
ARG NIGHTLY_BUILD
WORKDIR /build
# download dependencies before "ARG TARGETPLATFORM" otherwise it will be cached
# for each platform and that would take a lot of disk space
RUN --mount=type=bind,from=src,source=/src/go.mod,target=/build/go.mod \
    --mount=type=bind,from=src,source=/src/go.sum,target=/build/go.sum,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    go mod download -x
ARG TARGETPLATFORM
RUN xx-apt-get install -y gcc libc6-dev
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/compose \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/usr/local/src/compose pkg-static-build
FROM builder-static-nosdk AS builder-static-linux
FROM builder-static-nosdk AS builder-static-windows

FROM --platform=$BUILDPLATFORM ${DISTRO_IMAGE} AS builder-static-darwin
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates file git zip tar \
  dpkg-dev clang lld llvm make pkg-config
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"
ENV GO111MODULE="on"
ENV CGO_ENABLED="0"
ARG PKG_NAME
ARG PKG_REF
ARG NIGHTLY_BUILD
WORKDIR /build
# download dependencies before "ARG TARGETPLATFORM" otherwise it will be cached
# for each platform and that would take a lot of disk space
RUN --mount=type=bind,from=src,source=/src/go.mod,target=/build/go.mod \
    --mount=type=bind,from=src,source=/src/go.sum,target=/build/go.sum,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    go mod download -x
ARG TARGETPLATFORM
RUN xx-apt-get install -y gcc libc6-dev
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/compose \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=from=osxsdk,target=/xx-sdk,src=/xx-sdk \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/usr/local/src/compose pkg-static-build

FROM builder-static-$TARGETOS AS builder-static

FROM builder-${DISTRO_TYPE} AS build-pkg
ARG BUILDKIT_SBOM_SCAN_STAGE=true

FROM scratch AS pkg
COPY --from=build-pkg /out /
