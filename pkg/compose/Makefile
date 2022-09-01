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

include ../../vars.mk
include ../../packages.mk

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../packages.hcl

$(info $$BASEDIR = $(BASEDIR))
$(info $$COMPOSE_REPO = $(COMPOSE_REPO))
$(info $$COMPOSE_VERSION = $(COMPOSE_VERSION))

.PHONY: all
all: pkg-cross

.PHONY: pkg
pkg: pkg-apk pkg-deb pkg-rpm pkg-static

.PHONY: pkg-%
pkg-%: pkg-%-releases pkg-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),build-$(release))

.PHONY: pkg-static
pkg-static:
	$(MAKE) build-static

.PHONY: pkg-cross
pkg-cross: pkg-cross-apk pkg-cross-deb pkg-cross-rpm pkg-cross-static

.PHONY: pkg-%
pkg-cross-%: pkg-%-releases pkg-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),build-cross-$(release))

.PHONY: pkg-cross-static
pkg-cross-static:
	$(MAKE) build-cross-static

.PHONY: build-%
build-%: pkg-info-% pkg-info
	PKG_RELEASE=$* DESTDIR=$(DESTDIR) docker buildx bake $(BAKE_DEFINITIONS) pkg

.PHONY: build-cross-%
build-cross-%: pkg-info-% pkg-info
	$(eval $@_TMP_OUT := $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	PKG_RELEASE=$* DESTDIR=$($@_TMP_OUT) docker buildx bake $(BAKE_DEFINITIONS) pkg-cross
	mkdir -p $(DESTDIR)
	find $($@_TMP_OUT) -mindepth 2 -maxdepth 2 -type d -exec cp -rf {} $(DESTDIR)/ ';'
	find $(DESTDIR) -type d -empty -delete
	rm -rf "$($@_TMP_OUT)"
