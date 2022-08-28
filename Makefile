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

PKG_APK_RELEASES ?= r0
PKG_DEB_RELEASES ?= debian10 debian11 ubuntu1804 ubuntu2004 ubuntu2204 raspbian10 raspbian11
PKG_RPM_RELEASES ?= centos7 centos8 fedora33 fedora34 fedora35 fedora36

export BASEDIR = $(CURDIR)
export PKG_VENDOR ?= Docker
export PKG_PACKAGER ?= Docker <support@docker.com>

pkgs := $(notdir $(shell find "pkg/" -maxdepth 1 -type d))

.PHONY: apk deb rpm static
apk deb rpm static:
	$(foreach pkg,$(pkgs),$(MAKE) $@-$(pkg))

.PHONY: apk-%
apk-%:
	$(foreach release,$(PKG_APK_RELEASES),$(MAKE) -C pkg/$* pkg-cross-apk-$(release))

.PHONY: deb-%
deb-%:
	$(foreach release,$(PKG_DEB_RELEASES),$(MAKE) -C pkg/$* pkg-cross-deb-$(release))

.PHONY: rpm-%
rpm-%:
	$(foreach release,$(PKG_RPM_RELEASES),$(MAKE) -C pkg/$* pkg-cross-rpm-$(release))

.PHONY: static-%
static-%:
	$(MAKE) -C pkg/$* pkg-cross-static
