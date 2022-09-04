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

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../packages.hcl
PKG_LIST ?= deb rpm static
DEFAULT_RULE ?= pkg

export PKG_DEB_REVISION = 3
export PKG_RPM_RELEASE = 3

.PHONY: all
all: $(DEFAULT_RULE)
	# noop

.PHONY: all-%
all-%: $(DEFAULT_RULE)-%
	# noop

.PHONY: version
version:
	@echo $(DOCKER_CLI_VERSION)

include ../../packages.mk

.PHONY: pkg
pkg:
	$(MAKE) $(foreach pkg,$(PKG_LIST),pkg-$(pkg))

.PHONY: pkg-%
pkg-%: pkg-%-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),build-$(release))

.PHONY: pkg-static
pkg-static:
	$(MAKE) build-static

.PHONY: pkg-cross
pkg-cross:
	$(MAKE) $(foreach pkg,$(PKG_LIST),pkg-cross-$(pkg))

.PHONY: pkg-%
pkg-cross-%: pkg-%-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),build-cross-$(release))

.PHONY: pkg-cross-static
pkg-cross-static:
	$(MAKE) build-cross-static

.PHONY: build-%
build-%: pkg-info-%
	$(call run_bake,$*,$(DESTDIR),$(BAKE_DEFINITIONS),pkg)

.PHONY: build-cross-%
build-cross-%: pkg-info-%
	$(eval $@_TMP_OUT := $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	$(call run_bake,$*,$($@_TMP_OUT),$(BAKE_DEFINITIONS),pkg-cross)
	mkdir -p $(DESTDIR)
	find $($@_TMP_OUT) -mindepth 2 -maxdepth 2 -type d -exec cp -rf {} $(DESTDIR)/ ';'
	find $(DESTDIR) -type d -empty -delete
	rm -rf "$($@_TMP_OUT)"
