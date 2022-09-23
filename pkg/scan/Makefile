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
# supported platforms: https://github.com/docker/scan-cli-plugin/blob/9c797021449e3192a46ba86730d6f0e5409b6614/builder.Makefile#L62-L67
PKG_PLATFORMS ?= darwin/amd64 darwin/arm64 linux/amd64 linux/arm64 windows/amd64

.PHONY: all
all: $(DEFAULT_RULE)
	# noop

.PHONY: all-%
all-%: $(DEFAULT_RULE)-%
	# noop

.PHONY: version
version:
	@echo $(SCAN_VERSION)

include ../../common/packages.mk
include ../../common/build.mk
