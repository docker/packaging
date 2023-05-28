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

# https://github.com/containerd/containerd/blob/main/.github/workflows/release.yml#L16
export GO_VERSION = 1.20.4

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../common/packages.hcl

export CONTAINERD_REPO := $(if $(CONTAINERD_REPO),$(CONTAINERD_REPO),https://github.com/containerd/containerd.git)
export CONTAINERD_REF := $(if $(CONTAINERD_REF),$(CONTAINERD_REF),main)
export RUNC_REPO := $(if $(RUNC_REPO),$(RUNC_REPO),https://github.com/opencontainers/runc.git)
export RUNC_REF := $(if $(RUNC_REF),$(RUNC_REF),)

export PKG_DEB_REVISION = 1

PKG_LIST ?= deb rpm static
# supported platforms: https://github.com/containerd/containerd/blob/main/.github/workflows/ci.yml#L145-L165
# FIXME: can't build static binaries with containerd Makefile for darwin/amd64 darwin/arm64 windows/amd64 platforms
# FIXME: linux/riscv64 needs ubuntu:22.04 image
# FIXME: add linux/ppc64le when a remote PowerPC instance is available (too slow with QEMU)
PKG_PLATFORMS ?= linux/amd64 linux/arm/v5 linux/arm/v6 linux/arm/v7 linux/arm64 linux/s390x

.PHONY: default
default: pkg ;

.PHONY: metadata
metadata:
	docker buildx bake metadata

include ../../common/packages.mk
include ../../common/build.mk
