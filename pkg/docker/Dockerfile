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

ARG XX_VERSION="1.9.0"

# https://github.com/moby/moby/blob/master/Dockerfile#L157
ARG GOWINRES_VERSION="v0.3.1"

# https://github.com/docker/cli/blob/master/Dockerfile#L9
ARG GOVERSIONINFO_VERSION="v1.4.1"

ARG DISTRO_NAME="debian12"
ARG DISTRO_TYPE="deb"
ARG DISTRO_RELEASE="debian"
ARG DISTRO_ID="12"
ARG DISTRO_SUITE="bookworm"
ARG DISTRO_IMAGE="debian:bookworm"

ARG PKG_NAME="docker"
ARG PKG_REPO="https://github.com/docker/docker.git"
ARG PKG_REF="master"
ARG CLI_REPO="https://github.com/docker/cli.git"
ARG CLI_REF="master"
ARG DOCKER_VERSION

ARG GO_IMAGE="golang"
ARG GO_VERSION="1.26.5"
ARG GO_IMAGE_VARIANT="bookworm"

ARG TAGPREFIX="docker-"

# stage used as named context that mounts hack/scripts
# see pkg target in docker-bake.hcl
FROM scratch AS scripts

# cross compilation helper
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# go base image to retrieve /usr/local/go
FROM --platform=$BUILDPLATFORM ${GO_IMAGE}:${GO_VERSION}-${GO_IMAGE_VARIANT} AS gocross

# src
FROM --platform=$BUILDPLATFORM alpine AS src-base
RUN apk add --no-cache bash curl file git zip tar

FROM src-base AS engine-src
WORKDIR /src
ARG PKG_REPO
RUN git init . && git remote add origin "${PKG_REPO}"
ARG PKG_REF
RUN git fetch origin "${PKG_REF}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

FROM src-base AS cli-src
WORKDIR /src
ARG CLI_REPO
RUN git init . && git remote add origin "${CLI_REPO}"
ARG CLI_REF
RUN git fetch origin "${CLI_REF}" +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/* && git checkout -q FETCH_HEAD

# metadata
FROM src-base AS metadata-builder
ARG PKG_REPO
ARG PKG_REF
ARG CLI_REPO
ARG CLI_REF
ARG DOCKER_VERSION
ARG NIGHTLY_BUILD
ARG TAGPREFIX
RUN --mount=type=bind,from=scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=engine-src,source=/src,target=/engine-src \
    --mount=type=bind,from=cli-src,source=/src,target=/cli-src <<EOT
  set -e
  mkdir -p /out
  for l in $(gen-ver "/engine-src"); do
    export "ENGINE_${l?}"
  done
  for l in $(TAGPREFIX= gen-ver "/cli-src"); do
    export "CLI_${l?}"
  done
  dockerfile_arg() {
    name="$1"
    value=$(sed -n -E "s/^ARG ${name}=(.*)$/\1/p" "/engine-src/Dockerfile" | head -n1)
    value="${value#\"}"
    value="${value%\"}"
    if [ -z "$value" ]; then
      echo >&2 "error: ARG ${name} not found in /engine-src/Dockerfile"
      exit 1
    fi
    printf '%s\n' "$value"
  }
  CONTAINERD_VERSION="$(dockerfile_arg CONTAINERD_VERSION)"
  RUNC_VERSION="$(dockerfile_arg RUNC_VERSION)"
  VERSION="${DOCKER_VERSION:-${ENGINE_GENVER_VERSION}}"
  case "$VERSION" in
    v*) ;;
    *) VERSION="v${VERSION}" ;;
  esac
  cat > "/out/metadata.env" <<-EOF
REPO=${PKG_REPO%.*}
REF=${PKG_REF}
VERSION=${VERSION}
COMMIT=${ENGINE_GENVER_COMMIT}
CLI_REPO=${CLI_REPO%.*}
CLI_REF=${CLI_REF}
CLI_VERSION=${CLI_GENVER_VERSION}
CLI_COMMIT=${CLI_GENVER_COMMIT}
CONTAINERD_REPO=https://github.com/containerd/containerd
CONTAINERD_VERSION=${CONTAINERD_VERSION}
RUNC_REPO=https://github.com/opencontainers/runc
RUNC_VERSION=${RUNC_VERSION}
EOF
EOT

FROM scratch AS metadata
COPY --from=metadata-builder /out /

# static
FROM --platform=$BUILDPLATFORM ${DISTRO_IMAGE} AS build-base-static
COPY --from=xx / /
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates file git zip tar
ENV GOPROXY="https://proxy.golang.org|direct"
ENV GOPATH="/go"
ENV PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
ENV GOTOOLCHAIN="local"

FROM build-base-static AS gowinres
ARG GOWINRES_VERSION
RUN --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    GOBIN=/out GO111MODULE=on go install "github.com/tc-hib/go-winres@${GOWINRES_VERSION}"

FROM build-base-static AS goversioninfo
ARG GOVERSIONINFO_VERSION
RUN --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    GOBIN=/out GO111MODULE=on go install "github.com/josephspurrier/goversioninfo/cmd/goversioninfo@${GOVERSIONINFO_VERSION}"

FROM build-base-static AS builder-static
RUN apt-get install -y --no-install-recommends clang cmake dpkg-dev gcc libc6-dev lld llvm make pkg-config
ARG PKG_NAME
ARG PKG_REF
ARG CLI_REF
ARG DOCKER_VERSION
ARG NIGHTLY_BUILD
ARG TAGPREFIX
WORKDIR /build
ARG TARGETPLATFORM
RUN xx-apt-get install -y gcc libc6-dev libapparmor-dev libnftables-dev libsecret-1-dev libseccomp-dev libsystemd-dev libudev-dev linux-libc-dev pkg-config
RUN --mount=type=bind,source=scripts/pkg-static-build.sh,target=/usr/local/bin/pkg-static-build \
    --mount=type=bind,source=scripts/check-gomod.sh,target=/usr/local/bin/check-gomod \
    --mount=type=bind,from=scripts,source=gen-ver.sh,target=/usr/local/bin/gen-ver \
    --mount=type=bind,from=scripts,source=fix-cc.sh,target=/usr/local/bin/fix-cc \
    --mount=type=bind,from=scripts,source=write-sha256sum.sh,target=/usr/local/bin/write-sha256sum \
    --mount=type=bind,from=engine-src,source=/src,target=/go/src/github.com/docker/docker,rw \
    --mount=type=bind,from=cli-src,source=/src,target=/go/src/github.com/docker/cli,rw \
    --mount=type=bind,from=gocross,source=/usr/local/go,target=/usr/local/go,rw \
    --mount=type=bind,from=gowinres,source=/out/go-winres,target=/usr/bin/go-winres \
    --mount=type=bind,from=goversioninfo,source=/out/goversioninfo,target=/usr/bin/goversioninfo \
    --mount=type=tmpfs,target=/go/src/github.com/docker/docker/cli/winresources/dockerd \
    --mount=type=tmpfs,target=/go/src/github.com/docker/docker/cli/winresources/docker-proxy \
    --mount=type=tmpfs,target=/go/src/github.com/docker/cli/winresources \
    OUTDIR=/out BUILDDIR=/build ENGINE_SRCDIR=/go/src/github.com/docker/docker CLI_SRCDIR=/go/src/github.com/docker/cli pkg-static-build

FROM builder-${DISTRO_TYPE} AS build-pkg
ARG BUILDKIT_SBOM_SCAN_STAGE=true

FROM scratch AS pkg
COPY --from=build-pkg /out /
