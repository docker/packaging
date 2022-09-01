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

include vars.mk

pkgs := $(notdir $(shell find "pkg/" -maxdepth 1 -type d))

.PHONY: apk deb rpm static
apk deb rpm static:
	$(MAKE) $(foreach pkg,$(pkgs),$@-$(pkg))

.PHONY: apk-%
apk-%:
	$(MAKE) -C pkg/$* pkg-apk

.PHONY: deb-%
deb-%:
	$(MAKE) -C pkg/$* pkg-deb

.PHONY: rpm-%
rpm-%:
	$(MAKE) -C pkg/$* pkg-rpm

.PHONY: static-%
static-%:
	$(MAKE) -C pkg/$* pkg-static
