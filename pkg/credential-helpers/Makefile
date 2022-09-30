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

export CREDENTIAL_HELPERS_REPO ?= https://github.com/docker/docker-credential-helpers
export CREDENTIAL_HELPERS_VERSION ?= v0.7.0

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../common/packages.hcl

PKG_LIST ?= deb rpm static
# supported platforms: https://github.com/docker/docker-credential-helpers/blob/ac5992b5f4756fc0398a7d0c93c609e624368bde/docker-bake.hcl#L56-L66
# FIXME: add linux/ppc64le when a remote PowerPC instance is available (too slow with QEMU)
PKG_PLATFORMS ?= darwin/amd64 darwin/arm64 linux/amd64 linux/arm/v6 linux/arm/v7 linux/arm64 linux/s390x windows/amd64

define PKG_SUMMARY
* repo: $(CREDENTIAL_HELPERS_REPO)
* version: `$(CREDENTIAL_HELPERS_VERSION)`
endef

.PHONY: default
default: pkg ;

.PHONY: repo
repo:
	@echo $(CREDENTIAL_HELPERS_REPO)

.PHONY: version
version:
	@echo $(CREDENTIAL_HELPERS_VERSION)

export PKG_SUMMARY
.PHONY: summary
summary:
	@echo "$$PKG_SUMMARY"

include ../../common/packages.mk
include ../../common/build.mk
