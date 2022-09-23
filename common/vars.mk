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
export GO_IMAGE_VARIANT ?= bullseye

export PKG_VENDOR ?= Docker
export PKG_PACKAGER ?= Docker <support@docker.com>

## deb

# dpkg-buildpackage flags
export PKG_DEB_BUILDFLAGS ?= -b -uc
# Include an extra `.0` in the version, in case we ever would have to re-build
# an already published release with a packaging-only change.
export PKG_DEB_REVISION ?= 0
# Epoch is provided to allow mistakes in the version numbers of older versions
# of a package, and also a package's previous version numbering schemes,
# to be left behind. Should be enforce per package and not globally.
export PKG_DEB_EPOCH ?= 5

## rpm

# rpmbuild flags
export PKG_RPM_BUILDFLAGS ?= -bb
# rpm "Release:" field ($rpmRelease) is used to set the "_release" macro, which
# is an incremental number for builds of the same release (Version: / #rpmVersion)
# - Version: 0   : Package was built, but no matching upstream release (e.g., can be used for "nightly" builds)
# - Version: 1   : Package was built for an upstream (pre)release version
# - Version: > 1 : Only to be used for packaging-only changes (new package built for a version for which a package was already built/released)
export PKG_RPM_RELEASE ?= 1

## pkgs

export DOCKER_ENGINE_REPO ?= https://github.com/docker/docker.git
export DOCKER_CLI_REPO ?= https://github.com/docker/cli.git
export CONTAINERD_REPO ?= https://github.com/containerd/containerd.git
export BUILDX_REPO ?= https://github.com/docker/buildx.git
export COMPOSE_REPO ?= https://github.com/docker/compose.git
export SCAN_REPO ?= https://github.com/docker/scan-cli-plugin.git
export CREDENTIAL_HELPERS_REPO ?= https://github.com/docker/docker-credential-helpers.git

export DOCKER_ENGINE_VERSION ?= v20.10.17
export DOCKER_CLI_VERSION ?= v22.06.0-beta.0
export CONTAINERD_VERSION ?= v1.6.8
export BUILDX_VERSION ?= v0.9.1
export COMPOSE_VERSION ?= v2.10.2
export SCAN_VERSION ?= v0.19.0
export CREDENTIAL_HELPERS_VERSION ?= v0.7.0
