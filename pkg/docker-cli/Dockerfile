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

# https://github.com/docker/cli/blob/master/Dockerfile#L7
ARG GOVERSIONINFO_VERSION="v1.3.0"

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
ARG DOCKER_CLI_REPO
RUN git init . && git remote add origin "${DOCKER_CLI_REPO}"
ARG DOCKER_CLI_REF
RUN git fetch origin "${DOCKER_CLI_REF}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM src-base AS src-tgz
RUN --mount=from=src,source=/src,target=/cli \
    mkdir /out && tar -C / -zcf /out/cli.tgz --exclude .git cli

# metadata
FROM src-base AS metadata-builder
ARG DOCKER_CLI_REPO
ARG DOCKER_CLI_REF
ARG NIGHTLY_BUILD
RUN --mount=type=bind,from=common-scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=src,source=/src,target=/src <<EOT
  set -e
  mkdir -p /out
  for l in $(gen-ver "/src"); do
    export "${l?}"
  done
  cat > "/out/metadata.env" <<-EOF
REPO=${DOCKER_CLI_REPO%.*}
REF=${DOCKER_CLI_REF}
VERSION=${GENVER_VERSION}
COMMIT=${GENVER_COMMIT}
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
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ARG PKG_RELEASE
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils bash ca-certificates curl devscripts equivs git
RUN <<EOT
  set -e
  case "$PKG_RELEASE" in
    ubuntu2004|ubuntu2204|ubuntu2210|ubuntu2304)
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
ARG DOCKER_CLI_REF
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
    --mount=type=bind,from=src,source=/src,target=/root/package/cli,rw \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/root/package/cli pkg-deb-build

# rpm
FROM ${PKG_BASE_IMAGE} AS builder-rpm
COPY --from=xx / /
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV GO111MODULE="off"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
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
ARG DOCKER_CLI_REF
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
    --mount=type=bind,from=src-tgz,source=/out/cli.tgz,target=/root/rpmbuild/SOURCES/cli.tgz \
    --mount=type=bind,from=src,source=/src,target=/usr/local/src/cli \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    OUTDIR=/out SRCDIR=/usr/local/src/cli pkg-rpm-build

# static
FROM --platform=$BUILDPLATFORM ${PKG_BASE_IMAGE} AS build-base-static
COPY --from=xx / /
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates file git zip tar
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV CGO_ENABLED="0"
ENV GO111MODULE="off"

FROM build-base-static AS goversioninfo
ARG GOVERSIONINFO_VERSION
RUN --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    GOBIN=/out GO111MODULE=on go install "github.com/josephspurrier/goversioninfo/cmd/goversioninfo@${GOVERSIONINFO_VERSION}"

FROM build-base-static AS builder-static-nosdk
ARG DEBIAN_FRONTEND
RUN apt-get install -y --no-install-recommends dpkg-dev clang lld llvm make pkg-config
ARG PKG_NAME
ARG DOCKER_CLI_REF
ARG NIGHTLY_BUILD
WORKDIR /build
ARG TARGETPLATFORM
RUN xx-apt-get install -y gcc libc6-dev
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=common-scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=common-scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/docker/cli,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=bind,from=goversioninfo,source=/out/goversioninfo,target=/usr/bin/goversioninfo \
    --mount=type=tmpfs,target=/go/src/github.com/docker/cli/winresources \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/go/src/github.com/docker/cli pkg-static-build
FROM builder-static-nosdk AS builder-static-linux
FROM builder-static-nosdk AS builder-static-windows

FROM build-base-static AS builder-static-darwin
ARG DEBIAN_FRONTEND
RUN apt-get install -y --no-install-recommends dpkg-dev clang lld llvm make pkg-config
ARG PKG_NAME
ARG DOCKER_CLI_REF
ARG NIGHTLY_BUILD
WORKDIR /build
ARG TARGETPLATFORM
RUN xx-apt-get install -y gcc libc6-dev
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=common-scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=common-scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=src,source=/src,target=/go/src/github.com/docker/cli,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=bind,from=goversioninfo,source=/out/goversioninfo,target=/usr/bin/goversioninfo \
    --mount=from=osxsdk,target=/xx-sdk,src=/xx-sdk \
    --mount=type=tmpfs,target=/go/src/github.com/docker/cli/winresources \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/go/src/github.com/docker/cli pkg-static-build

FROM builder-static-$TARGETOS AS builder-static

FROM builder-${PKG_TYPE} AS build-pkg
ARG BUILDKIT_SBOM_SCAN_STAGE=true

FROM scratch AS pkg
COPY --from=build-pkg /out /
