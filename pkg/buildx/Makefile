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
DEFAULT_RULE ?= pkg-multi

PKG_LIST ?= apk deb rpm static
# supported platforms: https://github.com/docker/buildx/blob/e98c2524905e659d34ac01cc328cd21c966be3f2/docker-bake.hcl#L112-L124
PKG_PLATFORMS ?= darwin/amd64 darwin/arm64 linux/amd64 linux/arm/v6 linux/arm/v7 linux/arm64 linux/ppc64le linux/riscv64 linux/s390x windows/amd64 windows/arm64

.PHONY: all
all: $(DEFAULT_RULE)
	@#

.PHONY: all-%
all-%: $(DEFAULT_RULE)-%
	@#

.PHONY: version
version:
	@echo $(BUILDX_VERSION)

include ../../common/packages.mk
include ../../common/build.mk
