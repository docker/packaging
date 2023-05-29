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

ARG XX_VERSION="1.2.1"
ARG DEBIAN_FRONTEND="noninteractive"

# https://github.com/containerd/containerd/blob/main/.github/workflows/ci.yml#L132
ARG MD2MAN_VERSION="v2.0.2"

# common args
ARG GO_IMAGE="golang"
ARG GO_VERSION="1.20.4"
ARG GO_IMAGE_VARIANT="bullseye"
ARG PKG_RELEASE="debian11"
ARG PKG_TYPE="deb"
ARG PKG_DISTRO="debian"
ARG PKG_DISTRO_ID="11"
ARG PKG_DISTRO_SUITE="bullseye"
ARG PKG_BASE_IMAGE="debian:bullseye"

# stage used as named context that mounts common/scripts
# see pkg target in docker-bake.hcl
FROM scratch AS common-scripts

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# go base image to retrieve /usr/local/go
FROM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS gocross

# md2man
FROM go AS go-md2man
ARG GOPROXY="direct"
ARG GO111MODULE="on"
ARG MD2MAN_VERSION
RUN go install github.com/cpuguy83/go-md2man/v2@${MD2MAN_VERSION}

# src
FROM --platform=$BUILDPLATFORM alpine AS src-base
RUN apk add --no-cache bash curl file git zip tar

FROM src-base AS src
WORKDIR /src
ARG CONTAINERD_REPO
RUN git init . && git remote add origin "${CONTAINERD_REPO}"
ARG CONTAINERD_REF
RUN git fetch origin "${CONTAINERD_REF}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM src-base AS src-tgz
RUN --mount=from=src,source=/src,target=/containerd \
    mkdir /out && tar -C / -zcf /out/containerd.tgz --exclude .git containerd

FROM src-base AS runc-src
WORKDIR /src
ARG RUNC_REPO
ARG RUNC_REF
RUN git init . && git remote add origin "${RUNC_REPO}"
RUN --mount=from=src,source=/src,target=/containerd <<EOT
  [ -z "$RUNC_REF" ] && RUNC_REF=$(cat /containerd/script/setup/runc-version)
  git fetch origin "$RUNC_REF" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD
EOT

FROM src-base AS runc-src-tgz
RUN --mount=from=runc-src,source=/src,target=/runc \
    mkdir /out && tar -C / -zcf /out/runc.tgz --exclude .git runc

# metadata
FROM src-base AS metadata-builder
ARG CONTAINERD_REPO
ARG CONTAINERD_REF
ARG RUNC_REPO
ARG RUNC_REF
ARG NIGHTLY_BUILD
RUN --mount=type=bind,from=common-scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=src,source=/src,target=/src \
    --mount=type=bind,from=runc-src,source=/src,target=/runc-src <<EOT
  set -e
  mkdir -p /out
  for l in $(gen-ver "/src"); do
    export "${l?}"
  done
  cat > "/out/metadata.env" <<-EOF
REPO=${CONTAINERD_REPO%.*}
REF=${CONTAINERD_REF}
VERSION=${GENVER_VERSION}
COMMIT=${GENVER_COMMIT}
EOF
  [ -z "$RUNC_REF" ] && RUNC_REF=$(cat /src/script/setup/runc-version)
  for l in $(gen-ver "/runc-src"); do
    export "${l?}"
  done
  cat >> "/out/metadata.env" <<-EOF
RUNC_REPO=${RUNC_REPO%.*}
RUNC_REF=${RUNC_REF}
RUNC_VERSION=${GENVER_VERSION}
RUNC_COMMIT=${GENVER_COMMIT}
EOF
EOT

FROM scratch AS metadata
COPY --from=metadata-builder /out /

# deb
FROM ${PKG_BASE_IMAGE} AS builder-deb
COPY --from=xx / /
ARG DEBIAN_FRONTEND
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
COPY --from=go-md2man /go/bin/go-md2man $GOPATH/bin/go-md2man
ARG PKG_RELEASE
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils bash ca-certificates curl devscripts equivs git lsb-release
COPY deb /root/package/debian
ARG TARGETPLATFORM
RUN mk-build-deps -t "xx-apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i /root/package/debian/control
WORKDIR /root/package
ARG CONTAINERD_REF
ARG NIGHTLY_BUILD
ARG PKG_NAME
ARG PKG_DISTRO
ARG PKG_DISTRO_ID
ARG PKG_DISTRO_SUITE
ARG PKG_PACKAGER
ARG PKG_DEB_BUILDFLAGS
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-deb-build.sh,target=/usr/local/bin/pkg-deb-build \
    --mount=type=bind,from=common-scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=common-scripts,source=gen-deb-changelog.sh,target=/usr/local/bin/gen-deb-changelog \
    --mount=type=bind,from=common-scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,source=common,target=/common,rw \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/containerd/containerd,rw \
    --mount=type=bind,from=runc-src,source=/src,target=/go/src/github.com/opencontainers/runc,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/go/src/github.com/containerd/containerd pkg-deb-build

# rpm
FROM ${PKG_BASE_IMAGE} AS builder-rpm
COPY --from=xx / /
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
COPY --from=go-md2man /go/bin/go-md2man $GOPATH/bin/go-md2man
ARG PKG_RELEASE
RUN --mount=type=bind,from=common-scripts,source=rpm-init.sh,target=/usr/local/bin/rpm-init \
  rpm-init $PKG_RELEASE
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
  $builddepCmd -y /root/rpmbuild/SPECS/*.spec
EOT
WORKDIR /root/rpmbuild
ARG CONTAINERD_REF
ARG NIGHTLY_BUILD
ARG PKG_NAME
ARG PKG_DISTRO
ARG PKG_DISTRO_ID
ARG PKG_DISTRO_SUITE
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,from=common-scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=common-scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,source=common/containerd.toml,target=/root/rpmbuild/SOURCES/containerd.toml \
    --mount=type=bind,from=src-tgz,source=/out/containerd.tgz,target=/root/rpmbuild/SOURCES/containerd.tgz \
    --mount=type=bind,from=runc-src-tgz,source=/out/runc.tgz,target=/root/rpmbuild/SOURCES/runc.tgz \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/containerd/containerd,rw \
    --mount=type=bind,from=runc-src,source=/src,target=/go/src/github.com/opencontainers/runc,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/go/src/github.com/containerd/containerd pkg-rpm-build

# static
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS builder-static
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates file git zip tar \
  dpkg-dev git make pkg-config
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GO111MODULE="off"
ENV CGO_ENABLED="1"
ARG PKG_NAME
ARG CONTAINERD_REF
ARG NIGHTLY_BUILD
ARG RUNC_REF
WORKDIR /build
ARG TARGETPLATFORM
RUN xx-apt-get install -y libseccomp-dev gcc
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=common-scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=common-scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/containerd/containerd,rw \
    --mount=type=bind,from=runc-src,source=/src,target=/go/src/github.com/opencontainers/runc,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/go/src/github.com/containerd/containerd RUNC_SRCDIR=/go/src/github.com/opencontainers/runc pkg-static-build

FROM builder-${PKG_TYPE} AS build-pkg
ARG BUILDKIT_SBOM_SCAN_STAGE=true

FROM scratch AS pkg
COPY --from=build-pkg /out /
