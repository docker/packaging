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

export BASEDIR ?= $(CURDIR)
export GO_IMAGE ?= golang
export GO_VERSION ?= 1.18.5
export GO_IMAGE_VARIANT ?= buster

export PKG_VENDOR ?= Docker
export PKG_PACKAGER ?= Docker <support@docker.com>

export DOCKER_CLI_REPO ?= https://github.com/docker/cli.git
export BUILDX_REPO ?= https://github.com/docker/buildx.git
export COMPOSE_REPO ?= https://github.com/docker/compose.git
export CREDENTIAL_HELPERS_REPO ?= https://github.com/docker/docker-credential-helpers.git

export DOCKER_CLI_VERSION ?= v20.10.17
export BUILDX_VERSION ?= v0.9.1
export COMPOSE_VERSION ?= v2.10.2
export CREDENTIAL_HELPERS_VERSION ?= v0.7.0-beta.1

define run_bake
	@PKG_RELEASE=$(1) DESTDIR=$(2) docker buildx bake $(3) $(4) --print
	PKG_RELEASE=$(1) DESTDIR=$(2) docker buildx bake $(3) $(4)
endef
