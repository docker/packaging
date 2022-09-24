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

define run_bake
	$(eval $@_TMP_OUT := $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	@PKG_RELEASE=$(1) PKG_TYPE=$(PKG_TYPE) DESTDIR=$(2) docker buildx bake $(foreach platform,$(4),--set "*.platform=$(platform)") $(3) pkg --print
	PKG_RELEASE=$(1) PKG_TYPE=$(PKG_TYPE) DESTDIR=$($@_TMP_OUT) docker buildx bake $(foreach platform,$(4),--set "*.platform=$(platform)") $(3) pkg
	mkdir -p $(2)
	find $($@_TMP_OUT) -mindepth 2 -maxdepth 2 -type d -exec cp -rf {} $(2)/ ';'
	find $(2) -type d -empty -delete
	rm -rf "$($@_TMP_OUT)"
endef

define build_pkg
	$(eval FILTERED_PLATFORMS = $(filter $(PKG_SUPPORTED_PLATFORMS),$(4)))
	$(eval PLATFORMS = $(if $(PKG_SUPPORTED_PLATFORMS:-=),$(FILTERED_PLATFORMS),$(4)))
	$(if $(PLATFORMS:-=),$(call run_bake,$(1),$(2),$(3),$(PLATFORMS)),$(info no platform compatible for $(1)))
endef

.PHONY: pkg
pkg:
	$(MAKE) $(foreach pkg,$(PKG_LIST),pkg-$(pkg))

.PHONY: pkg-%
pkg-%: pkg-%-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),build-$(release))

.PHONY: pkg-static
pkg-static:
	$(MAKE) build-static

.PHONY: pkg-multi
pkg-multi:
	$(MAKE) $(foreach pkg,$(PKG_LIST),pkg-multi-$(pkg))

.PHONY: pkg-%
pkg-multi-%: pkg-%-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),build-multi-$(release))

.PHONY: pkg-multi-static
pkg-multi-static:
	$(MAKE) build-multi-static

.PHONY: build-%
build-%: pkg-info-%
	$(call build_pkg,$*,$(DESTDIR),$(BAKE_DEFINITIONS),)

.PHONY: build-multi-%
build-multi-%: pkg-info-%
	$(call build_pkg,$*,$(DESTDIR),$(BAKE_DEFINITIONS),$(PKG_PLATFORMS))
