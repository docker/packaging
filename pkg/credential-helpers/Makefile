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

# https://github.com/docker/docker-credential-helpers/blob/master/Dockerfile#L3
export GO_VERSION = 1.20.4

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../common/packages.hcl

export CREDENTIAL_HELPERS_REPO := $(if $(CREDENTIAL_HELPERS_REPO),$(CREDENTIAL_HELPERS_REPO),https://github.com/docker/docker-credential-helpers.git)
export CREDENTIAL_HELPERS_REF := $(if $(CREDENTIAL_HELPERS_REF),$(CREDENTIAL_HELPERS_REF),master)

PKG_LIST ?= deb rpm static
# supported platforms: https://github.com/docker/docker-credential-helpers/blob/master/docker-bake.hcl#L56-L66
# FIXME: add linux/ppc64le when a remote PowerPC instance is available (too slow with QEMU)
PKG_PLATFORMS ?= darwin/amd64 darwin/arm64 linux/amd64 linux/arm/v5 linux/arm/v6 linux/arm/v7 linux/arm64 linux/s390x windows/amd64

.PHONY: default
default: pkg ;

.PHONY: metadata
metadata:
	docker buildx bake metadata

include ../../common/packages.mk
include ../../common/build.mk
