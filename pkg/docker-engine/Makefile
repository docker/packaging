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

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../common/packages.hcl

PKG_LIST ?= deb rpm static
# supported platforms: https://github.com/moby/moby/blob/0e873d5cd8b31c08e29ff2f790c19a2e9c4ee30a/.github/workflows/ci.yml#L65-L73
# FIXME: add linux/ppc64le when a remote PowerPC instance is available (too slow with QEMU)
PKG_PLATFORMS ?= linux/amd64 linux/arm/v7 linux/arm64 linux/s390x windows/amd64

export PKG_DEB_REVISION = 3
export PKG_RPM_RELEASE = 3

.PHONY: all
all: pkg
	@#

.PHONY: all-%
all-%: pkg-%
	@#

.PHONY: version
version:
	@echo $(DOCKER_ENGINE_VERSION)

include ../../common/packages.mk
include ../../common/build.mk
