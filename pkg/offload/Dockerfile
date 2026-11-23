# syntax=docker/dockerfile:1

# Copyright 2026 Docker Packaging authors
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

ARG XX_VERSION="1.10.0"

ARG DISTRO_NAME="debian13"
ARG DISTRO_TYPE="deb"
ARG DISTRO_RELEASE="debian"
ARG DISTRO_SUITE="trixie"
ARG DISTRO_ID="13"
ARG DISTRO_IMAGE="debian:trixie"

ARG PKG_NAME="docker-offload-plugin"

ARG GO_IMAGE="golang"
# Must be the exact Go version of the release build, so the package build reproduces it.
ARG GO_VERSION="1.27.3"
ARG GO_IMAGE_VARIANT="trixie"

# stage used as named context that mounts hack/scripts
# see pkg target in docker-bake.hcl
FROM scratch AS scripts

# The source tree is private and is passed in by the caller as the src named context, with
# Go dependencies already vendored. There is no git clone fallback.
FROM scratch AS src

# THIRD-PARTY-NOTICES of the release, passed in by the caller as the notices named context. The
# file is at the root of the context. There is no fallback, the build fails without it.
FROM scratch AS notices

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# go base image to retrieve /usr/local/go
FROM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go

# go toolchain for the build platform, used by static to cross compile for any target platform
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS go-build

# deb
FROM ${DISTRO_IMAGE} AS builder-deb
COPY --from=xx / /
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"
ARG DISTRO_NAME
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils bash ca-certificates devscripts equivs
COPY deb /root/package/debian
ARG TARGETPLATFORM
RUN mk-build-deps -t "xx-apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i /root/package/debian/control
WORKDIR /root/package
ARG VERSION
ARG COMMIT
ARG BUILD
ARG DATE
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG PKG_NAME
ARG PKG_PACKAGER
ARG PKG_DEB_BUILDFLAGS
ARG PKG_DEB_REVISION
ARG PKG_DEB_EPOCH
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-deb-build.sh,target=/usr/local/bin/pkg-deb-build \
    --mount=type=bind,from=scripts,source=gen-deb-changelog.sh,target=/usr/local/bin/gen-deb-changelog \
    --mount=type=bind,from=src,target=/root/package/offload,rw \
    --mount=type=bind,from=notices,target=/root/package/notices \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=secret,id=build-env,target=/run/secrets/build-env \
    OUTDIR=/out SRCDIR=./offload NOTICESDIR=./notices \
    BUILD_ENV_FILE=/run/secrets/build-env pkg-deb-build

# rpm
FROM ${DISTRO_IMAGE} AS builder-rpm
COPY --from=xx / /
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"
ARG DISTRO_NAME
RUN --mount=type=bind,from=scripts,source=rpm-init.sh,target=/usr/local/bin/rpm-init \
  rpm-init $DISTRO_NAME
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN --mount=type=bind,from=scripts,source=rpm-builddep.sh,target=/usr/local/bin/rpm-builddep \
  rpm-builddep $(xx-info rhel-arch) /root/rpmbuild/SPECS
WORKDIR /root/rpmbuild
ARG VERSION
ARG COMMIT
ARG BUILD
ARG DATE
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG PKG_NAME
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,from=src,target=/usr/local/src/offload,rw \
    --mount=type=bind,from=notices,target=/usr/local/src/notices \
    --mount=type=bind,from=go,source=/usr/local/go,target=/usr/local/go \
    --mount=type=secret,id=build-env,target=/run/secrets/build-env \
    OUTDIR=/out SRCDIR=/usr/local/src/offload NOTICESDIR=/usr/local/src/notices \
    BUILD_ENV_FILE=/run/secrets/build-env pkg-rpm-build

# static
# Compiles from source, like the deb and rpm builders, and archives the unsigned binary.
FROM --platform=$BUILDPLATFORM ${DISTRO_IMAGE} AS builder-static
COPY --from=xx / /
RUN apt-get update && apt-get install -y --no-install-recommends bash file make tar zip
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"
ARG PKG_NAME
ARG VERSION
ARG COMMIT
ARG BUILD
ARG DATE
WORKDIR /build
ARG TARGETPLATFORM
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,from=scripts,source=write-sha256sum.sh,target=/usr/local/bin/write-sha256sum \
    --mount=type=bind,from=src,target=/usr/local/src/offload,rw \
    --mount=type=bind,from=notices,target=/usr/local/src/notices \
    --mount=type=bind,from=go-build,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=secret,id=build-env,target=/run/secrets/build-env \
    OUTDIR=/out BUILDDIR=/build SRCDIR=/usr/local/src/offload NOTICESDIR=/usr/local/src/notices \
    BUILD_ENV_FILE=/run/secrets/build-env pkg-static-build

FROM builder-${DISTRO_TYPE} AS build-pkg
ARG BUILDKIT_SBOM_SCAN_STAGE=true

FROM scratch AS pkg
COPY --from=build-pkg /out /
