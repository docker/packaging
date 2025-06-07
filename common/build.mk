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

define bake
	$(eval $@_TMP_OUT = $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	@PKG_RELEASE=$(1) PKG_TYPE=$(PKG_TYPE) DESTDIR=$(2) docker buildx bake --allow=fs=* $(foreach platform,$(5),--set "*.platform=$(platform)") $(3) $(4) --print
	PKG_RELEASE=$(1) PKG_TYPE=$(PKG_TYPE) DESTDIR=$($@_TMP_OUT) docker buildx bake --allow=fs=* $(foreach platform,$(5),--set "*.platform=$(platform)") $(3) $(4)
	mkdir -p $(2)
	set -e; \
		if [ "$(4)" = "pkg" ]; then \
			for pdir in "$($@_TMP_OUT)"/*/; do \
				attestdest=$$(find $${pdir} -type d -print | sort -n | tail -1); \
				mv $${pdir}/sbom-build*.json $${attestdest}/sbom.json; \
				mv $${pdir}/provenance.json $${attestdest}/provenance.json; \
			done \
		fi
	find $($@_TMP_OUT) -mindepth 2 -maxdepth 2 -type d -exec cp -rf {} $(2)/ ';'
	find $(2) -type d -empty -delete
	rm -rf "$($@_TMP_OUT)"
endef

# build will filter PKG_SUPPORTED_PLATFORMS of the base pkg image with
# projects ones in $(5) and call run_bake. If LIMITED_PLATFORMS is set, then it
# will filter against those. If LOCAL_PLATFORM is set, then it will build only
# for the current local platform (no platform passed). Static package is a
# special case where PKG_SUPPORTED_PLATFORMS is always empty as this kind of
# package is built with cross compilation support and therefore all supported
# platforms of the project are always passed.
define build
	$(eval SUPPORTED_PLATFORMS = $(if $(LIMITED_PLATFORMS:-=),$(LIMITED_PLATFORMS),$(5)))
	$(eval FILTERED_PLATFORMS = $(filter $(PKG_SUPPORTED_PLATFORMS),$(SUPPORTED_PLATFORMS)))
	$(eval BUILD_PLATFORMS = $(if $(PKG_SUPPORTED_PLATFORMS:-=),$(FILTERED_PLATFORMS),$(5)))
	$(if $(LOCAL_PLATFORM:-=), \
		$(call bake,$(1),$(2),$(3),$(4),), \
		$(if $(BUILD_PLATFORMS:-=), \
			$(call bake,$(1),$(2),$(3),$(4),$(BUILD_PLATFORMS)), \
			$(info $(SUPPORTED_PLATFORMS) platform(s) not supported by $(1)) \
		) \
	)
endef

.PHONY: pkg
pkg:
	$(MAKE) $(foreach pkg,$(PKG_LIST),pkg-$(pkg))

.PHONY: pkg-%
pkg-%: pkg-%-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),run-pkg-$(release))

.PHONY: run-pkg-%
run-pkg-%: pkg-info-%
	$(call build,$*,$(DESTDIR),$(BAKE_DEFINITIONS),pkg,$(PKG_PLATFORMS))

.PHONY: verify
verify:
	$(MAKE) $(foreach pkg,$(PKG_LIST),verify-$(pkg))

.PHONY: verify-%
verify-%: pkg-%-releases
	$(MAKE) $(foreach release,$(PKG_RELEASES),run-verify-$(release))

.PHONY: run-verify-%
run-verify-%: platform pkg-info-%
	$(call build,$*,$(DESTDIR),$(BAKE_DEFINITIONS),verify,$(PLATFORM))

.PHONY: platform
platform:
	$(eval $@_TMP_OUT = $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	$(shell echo 'FROM busybox:1.35\nARG TARGETPLATFORM\nRUN mkdir /out && echo "$$TARGETPLATFORM" > /out/platform' | docker buildx build --platform local -q --output "$($@_TMP_OUT)" -)
	$(eval PLATFORM = $(shell cat $($@_TMP_OUT)/out/platform))
	@rm -rf "$($@_TMP_OUT)"
