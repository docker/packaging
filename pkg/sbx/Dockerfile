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

ARG XX_VERSION="1.9.0"

ARG DISTRO_NAME="debian12"
ARG DISTRO_TYPE="deb"
ARG DISTRO_RELEASE="debian"
ARG DISTRO_SUITE="bookworm"
ARG DISTRO_ID="12"
ARG DISTRO_IMAGE="debian:bookworm"

ARG PKG_NAME="docker-sbx"
ARG VERSION

ARG EROFS_UTILS_REPO="https://github.com/erofs/erofs-utils.git"
ARG EROFS_UTILS_VERSION="v1.9.1"

# stage used as named context that mounts hack/scripts
# see pkg target in docker-bake.hcl
FROM scratch AS scripts

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# Pre-built binary from the sbx repo's own Dockerfile (binaries target).
# Overridden via named context in docker-bake.hcl.
FROM scratch AS sbx-src

# Pre-built runtime binaries fetched by scripts/fetch-runtime-binaries.sh.
# Overridden via named context in docker-bake.hcl.
FROM scratch AS runtime-src

# Clone erofs-utils source for building inside each distro-specific builder.
FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS erofs-src
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git
ARG EROFS_UTILS_REPO
ARG EROFS_UTILS_VERSION
RUN git clone --depth 1 --branch "${EROFS_UTILS_VERSION}" "${EROFS_UTILS_REPO}" /src/erofs-utils

# deb
FROM ${DISTRO_IMAGE} AS builder-deb
COPY --from=xx / /
ARG DISTRO_NAME
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils bash ca-certificates devscripts equivs
COPY deb /root/package/debian
COPY THIRD-PARTY-NOTICES /root/package/THIRD-PARTY-NOTICES
ARG TARGETPLATFORM
RUN mk-build-deps -t "xx-apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i /root/package/debian/control
WORKDIR /root/package
ARG NIGHTLY_BUILD
ARG VERSION
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
    --mount=type=bind,source=scripts/build-erofs.sh,target=/usr/local/bin/build-erofs \
    --mount=type=bind,from=scripts,source=gen-deb-changelog.sh,target=/usr/local/bin/gen-deb-changelog \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=sbx-src,target=/opt/sbx-bin \
    --mount=type=bind,from=runtime-src,target=/opt/runtime-bin \
    --mount=type=bind,from=erofs-src,source=/src/erofs-utils,target=/opt/erofs-src \
    --mount=type=bind,source=apparmor,target=/opt/apparmor \
    --mount=type=bind,source=licenses,target=/opt/licenses \
    OUTDIR=/out pkg-deb-build

# rpm
FROM ${DISTRO_IMAGE} AS builder-rpm
COPY --from=xx / /
ARG DISTRO_NAME
RUN --mount=type=bind,from=scripts,source=rpm-init.sh,target=/usr/local/bin/rpm-init \
  rpm-init $DISTRO_NAME
COPY rpm /root/rpmbuild/SPECS
ARG TARGETPLATFORM
RUN --mount=type=bind,from=scripts,source=rpm-builddep.sh,target=/usr/local/bin/rpm-builddep \
  rpm-builddep $(xx-info rhel-arch) /root/rpmbuild/SPECS
WORKDIR /root/rpmbuild
ARG NIGHTLY_BUILD
ARG VERSION
ARG DISTRO_RELEASE
ARG DISTRO_ID
ARG DISTRO_SUITE
ARG PKG_NAME
ARG PKG_PACKAGER
ARG PKG_RPM_BUILDFLAGS
ARG PKG_RPM_RELEASE
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=scripts/pkg-rpm-build.sh,target=/usr/local/bin/pkg-rpm-build \
    --mount=type=bind,source=scripts/build-erofs.sh,target=/usr/local/bin/build-erofs \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=sbx-src,target=/opt/sbx-bin \
    --mount=type=bind,from=runtime-src,target=/opt/runtime-bin \
    --mount=type=bind,from=erofs-src,source=/src/erofs-utils,target=/opt/erofs-src \
    --mount=type=bind,source=apparmor,target=/opt/apparmor \
    --mount=type=bind,source=THIRD-PARTY-NOTICES,target=/opt/notices/THIRD-PARTY-NOTICES \
    --mount=type=bind,source=licenses,target=/opt/licenses \
    OUTDIR=/out pkg-rpm-build

# static
FROM --platform=$BUILDPLATFORM ${DISTRO_IMAGE} AS builder-static
COPY --from=xx / /
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates file zip tar
ARG PKG_NAME
ARG VERSION
ARG NIGHTLY_BUILD
WORKDIR /build
ARG TARGETPLATFORM
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,source=scripts/build-erofs.sh,target=/usr/local/bin/build-erofs \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=sbx-src,target=/opt/sbx-bin \
    --mount=type=bind,from=runtime-src,target=/opt/runtime-bin \
    --mount=type=bind,from=erofs-src,source=/src/erofs-utils,target=/opt/erofs-src \
    --mount=type=bind,source=THIRD-PARTY-NOTICES,target=/opt/notices/THIRD-PARTY-NOTICES \
    --mount=type=bind,source=licenses,target=/opt/licenses \
    OUTDIR=/out BUILDDIR=/build pkg-static-build

FROM builder-${DISTRO_TYPE} AS build-pkg
ARG BUILDKIT_SBOM_SCAN_STAGE=true

FROM scratch AS pkg
COPY --from=build-pkg /out /
