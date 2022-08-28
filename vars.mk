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

export BUILDX_REPO ?= https://github.com/docker/buildx.git
export COMPOSE_REPO ?= https://github.com/docker/compose.git

export BUILDX_VERSION ?= v0.9.1
export COMPOSE_VERSION ?= v2.10.2

buildx-version:
	@echo $(BUILDX_VERSION)

compose-version:
	@echo $(COMPOSE_VERSION)
