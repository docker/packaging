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
	@PKG_RELEASE=$(1) DESTDIR=$(2) docker buildx bake $(3) $(4) --print
	$(eval $@_TMP_OUT := $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	PKG_RELEASE=$(1) DESTDIR=$($@_TMP_OUT) docker buildx bake $(3) $(4)
	mkdir -p $(2)
	find $($@_TMP_OUT) -mindepth 2 -maxdepth 2 -type d -exec cp -rf {} $(2)/ ';'
	find $(2) -type d -empty -delete
	rm -rf "$($@_TMP_OUT)"
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
	$(call run_bake,$*,$(DESTDIR),$(BAKE_DEFINITIONS),pkg-cross)
