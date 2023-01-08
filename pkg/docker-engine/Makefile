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

include ../../common/vars.mk

# https://github.com/moby/moby/blob/v23.0.0-rc.1/Dockerfile#L3
export GO_VERSION = 1.19.4

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../common/packages.hcl

export DOCKER_ENGINE_REPO := $(if $(DOCKER_ENGINE_REPO),$(DOCKER_ENGINE_REPO),https://github.com/docker/docker.git)
export DOCKER_ENGINE_REF := $(if $(DOCKER_ENGINE_REF),$(DOCKER_ENGINE_REF),v23.0.0-rc.1)

export PKG_DEB_REVISION = 3
export PKG_RPM_RELEASE = 3

PKG_LIST ?= deb rpm static
# supported platforms: https://github.com/moby/moby/blob/0e873d5cd8b31c08e29ff2f790c19a2e9c4ee30a/.github/workflows/ci.yml#L65-L73
# FIXME: add linux/ppc64le when a remote PowerPC instance is available (too slow with QEMU)
PKG_PLATFORMS ?= linux/amd64 linux/arm/v6 linux/arm/v7 linux/arm64 linux/s390x windows/amd64 windows/arm64

.PHONY: default
default: pkg ;

.PHONY: metadata
metadata:
	docker buildx bake metadata

include ../../common/packages.mk
include ../../common/build.mk
