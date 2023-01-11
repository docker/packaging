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

# https://github.com/docker/sbom-cli-plugin/blob/main/.github/workflows/release.yaml#L12
export GO_VERSION = 1.18

DESTDIR ?= $(BASEDIR)/bin
BAKE_DEFINITIONS ?= -f docker-bake.hcl -f ../../common/packages.hcl

export SBOM_REPO := $(if $(SBOM_REPO),$(SBOM_REPO),https://github.com/docker/sbom-cli-plugin.git)
export SBOM_REF := $(if $(SBOM_REF),$(SBOM_REF),main)

PKG_LIST ?= deb rpm static
# supported platforms: https://github.com/docker/sbom-cli-plugin/blob/main/.goreleaser.yaml#L7-L13
PKG_PLATFORMS ?= darwin/amd64 darwin/arm64 linux/amd64 linux/arm64 windows/amd64 windows/arm64

.PHONY: default
default: pkg ;

.PHONY: metadata
metadata:
	docker buildx bake metadata

include ../../common/packages.mk
include ../../common/build.mk
