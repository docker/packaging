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

# go base image
export GO_IMAGE ?= golang
export GO_VERSION ?= 1.21.3
export GO_IMAGE_VARIANT ?= bullseye

# if set, ony build matching the local platform
# e.g., LOCAL_PLATFORM=1 make deb
export LOCAL_PLATFORM ?=

# limit set of platforms to build against (for testing purpose)
# e.g., LIMITED_PLATFORMS="linux/arm64 linux/arm/v7" make deb
export LIMITED_PLATFORMS ?=

# package metadata
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
export PKG_RPM_RELEASE ?=
