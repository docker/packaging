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

DESTDIR ?= $(BASEDIR)/bin/local
BAKE_TARGET ?= pkg

word-hypen = $(word $2,$(subst -, ,$1))

$(info $$BASEDIR = $(BASEDIR))
$(info $$BUILDX_REPO = $(BUILDX_REPO))
$(info $$BUILDX_VERSION = $(BUILDX_VERSION))

.PHONY: pkg
pkg: pkg-apk pkg-deb pkg-rpm pkg-static

.PHONY: pkg-apk
pkg-apk:
	$(MAKE) $(foreach release,$(PKG_APK_RELEASES),build-cross-apk-$(release))

.PHONY: pkg-apk
pkg-deb:
	$(MAKE) $(foreach release,$(PKG_DEB_RELEASES),build-cross-deb-$(release))

.PHONY: pkg-rpm
pkg-rpm:
	$(MAKE) $(foreach release,$(PKG_RPM_RELEASES),build-cross-rpm-$(release))

.PHONY: static
pkg-static:
	$(MAKE) build-cross-static

.PHONY: build-%
build-%:
	$(eval pkg_type=$(call word-hypen,$*,1))
	$(eval pkg_release=$(call word-hypen,$*,2))
	PKG_TYPE=$(pkg_type) PKG_RELEASE=$(pkg_release) DESTDIR=$(DESTDIR) docker buildx bake $(BAKE_TARGET)

.PHONY: build-cross-%
build-cross-%:
	$(eval pkg_type=$(call word-hypen,$*,1))
	$(eval pkg_release=$(call word-hypen,$*,2))
	$(eval target=build-$(pkg_type)-$(pkg_release))
	$(eval $@_TMP_OUT := $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	$(MAKE) $(target:%-=%) DESTDIR=$($@_TMP_OUT) BAKE_TARGET=pkg-cross
	$(eval DESTDIR = $(BASEDIR)/bin/$(pkg_type))
	mkdir -p $(DESTDIR)
	find $($@_TMP_OUT) -mindepth 2 -maxdepth 2 -type d -exec cp -rf {} $(DESTDIR)/ ';'
	find $(DESTDIR) -type d -empty -delete
	rm -rf "$($@_TMP_OUT)"
