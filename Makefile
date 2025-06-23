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

# Same as ones in docker-bake.hcl
DISTROS ?= static \
	\
	debian11 \
	debian12 \
	debian13 \
	raspbian11 \
	raspbian12 \
	ubuntu2204 \
	ubuntu2404 \
	\
	almalinux8 \
	almalinux9 \
	centos9 \
	fedora41 \
	fedora42 \
	oraclelinux8 \
	oraclelinux9 \
	rhel8 \
	rhel9 \
	rockylinux8 \
	rockylinux9

# Should match ones from docker-bake.hcl
PKGS_RAW := $(notdir $(shell find "pkg/" -maxdepth 1 -type d))
PKGS := $(foreach pkg,$(PKGS_RAW),pkg-$(pkg))

.PHONY: clean
clean:
	rm -rf ./bin/*

.PHONY: $(PKGS)
$(PKGS):
	@pkg=$$(echo $@ | sed 's/^pkg-//'); \
	targets=""; \
	for distro in $(DISTROS); do \
		targets="$$targets pkg-$$pkg-$$distro"; \
	done; \
	docker buildx bake $$targets --print; \
	docker buildx bake $$targets
