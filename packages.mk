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

# don't forget to add/update pkg-info-* rule and update packages.hcl as well
# if you add a new release
PKG_APK_RELEASES ?= alpine314 alpine315 alpine316
PKG_DEB_RELEASES ?= debian10 debian11 ubuntu1804 ubuntu2004 ubuntu2204 raspbian10 raspbian11
PKG_RPM_RELEASES ?= centos7 centos8 centos9 fedora35 fedora36 fedora37 oraclelinux7 oraclelinux8 oraclelinux9

.PHONY: pkg-releases
pkg-releases:
	$(info $$PKG_RELEASES = $(PKG_RELEASES))

.PHONY: pkg-apk-releases
pkg-apk-releases:
	$(eval PKG_RELEASES = $(PKG_APK_RELEASES))

.PHONY: pkg-deb-releases
pkg-deb-releases:
	$(eval PKG_RELEASES = $(PKG_DEB_RELEASES))

.PHONY: pkg-rpm-releases
pkg-rpm-releases:
	$(eval PKG_RELEASES = $(PKG_RPM_RELEASES))

.PHONY: pkg-info
pkg-info:
	$(info $$PKG_TYPE = $(PKG_TYPE))
	$(info $$PKG_DISTRO = $(PKG_DISTRO))
	$(info $$PKG_SUITE = $(PKG_SUITE))
	$(info $$PKG_BASE_IMAGE = $(PKG_BASE_IMAGE))
	$(info $$PKG_SUPPORTED_ARCHS = $(PKG_SUPPORTED_ARCHS))

.PHONY: pkg-info-alpine314
pkg-info-alpine314:
	$(eval PKG_TYPE = apk)
	$(eval PKG_DISTRO = alpine)
	$(eval PKG_SUITE = 3.14)
	$(eval PKG_BASE_IMAGE = alpine:3.14)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 armv7l armv6l armv5l ppc64le s390x)

.PHONY: pkg-info-alpine315
pkg-info-alpine315:
	$(eval PKG_TYPE = apk)
	$(eval PKG_DISTRO = alpine)
	$(eval PKG_SUITE = 3.15)
	$(eval PKG_BASE_IMAGE = alpine:3.15)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 armv7l armv6l armv5l ppc64le s390x)

.PHONY: pkg-info-alpine316
pkg-info-alpine316:
	$(eval PKG_TYPE = apk)
	$(eval PKG_DISTRO = alpine)
	$(eval PKG_SUITE = 3.16)
	$(eval PKG_BASE_IMAGE = alpine:3.16)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 armv7l armv6l armv5l ppc64le s390x)

.PHONY: pkg-info-debian10
pkg-info-debian10:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = debian)
	$(eval PKG_SUITE = buster)
	$(eval PKG_BASE_IMAGE = debian:buster)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 armv7l armv6l ppc64le riscv64 s390x)

.PHONY: pkg-info-debian11
pkg-info-debian11:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = debian)
	$(eval PKG_SUITE = bullseye)
	$(eval PKG_BASE_IMAGE = debian:bullseye)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 armv7l armv6l ppc64le riscv64 s390x)

.PHONY: pkg-info-raspbian10
pkg-info-raspbian10:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = raspbian)
	$(eval PKG_SUITE = buster)
	$(eval PKG_BASE_IMAGE = raspbian:buster)
	$(eval PKG_SUPPORTED_ARCHS = armv6l)

.PHONY: pkg-info-raspbian11
pkg-info-raspbian11:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = raspbian)
	$(eval PKG_SUITE = bullseye)
	$(eval PKG_BASE_IMAGE = raspbian:bullseye)
	$(eval PKG_SUPPORTED_ARCHS = armv6l)

.PHONY: pkg-info-ubuntu1804
pkg-info-ubuntu1804:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = ubuntu)
	$(eval PKG_SUITE = bionic)
	$(eval PKG_BASE_IMAGE = ubuntu:bionic)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 armv7l ppc64le s390x)

.PHONY: pkg-info-ubuntu2004
pkg-info-ubuntu2004:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = ubuntu)
	$(eval PKG_SUITE = focal)
	$(eval PKG_BASE_IMAGE = ubuntu:focal)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64 armv7l ppc64le riscv64 s390x)

.PHONY: pkg-info-ubuntu2204
pkg-info-ubuntu2204:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = ubuntu)
	$(eval PKG_SUITE = jammy)
	$(eval PKG_BASE_IMAGE = ubuntu:jammy)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64 armv7l ppc64le riscv64 s390x)

.PHONY: pkg-info-centos7
pkg-info-centos7:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = centos)
	$(eval PKG_SUITE = 7)
	$(eval PKG_BASE_IMAGE = centos:7)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 armv7l ppc64le)

.PHONY: pkg-info-centos8
pkg-info-centos8:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = centos)
	$(eval PKG_SUITE = 8)
	$(eval PKG_BASE_IMAGE = quay.io/centos/centos:stream8)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 ppc64le)

.PHONY: pkg-info-centos9
pkg-info-centos9:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = centos)
	$(eval PKG_SUITE = 9)
	$(eval PKG_BASE_IMAGE = quay.io/centos/centos:stream9)
	$(eval PKG_SUPPORTED_ARCHS = i386 x86_64 aarch64 arm64 ppc64le s390x)

.PHONY: pkg-info-fedora35
pkg-info-fedora35:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = fedora)
	$(eval PKG_SUITE = 35)
	$(eval PKG_BASE_IMAGE = fedora:35)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64 armv7l ppc64le s390x)

.PHONY: pkg-info-fedora36
pkg-info-fedora36:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = fedora)
	$(eval PKG_SUITE = 36)
	$(eval PKG_BASE_IMAGE = fedora:36)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64 armv7l ppc64le s390x)

.PHONY: pkg-info-fedora37
pkg-info-fedora37:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = fedora)
	$(eval PKG_SUITE = 37)
	$(eval PKG_BASE_IMAGE = fedora:37)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64 ppc64le s390x)

.PHONY: pkg-info-oraclelinux7
pkg-info-oraclelinux7:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = oraclelinux)
	$(eval PKG_SUITE = 7)
	$(eval PKG_BASE_IMAGE = oraclelinux:7)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64)

.PHONY: pkg-info-oraclelinux8
pkg-info-oraclelinux8:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = oraclelinux)
	$(eval PKG_SUITE = 8)
	$(eval PKG_BASE_IMAGE = oraclelinux:8)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64)

.PHONY: pkg-info-oraclelinux9
pkg-info-oraclelinux9:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = oraclelinux)
	$(eval PKG_SUITE = 9)
	$(eval PKG_BASE_IMAGE = oraclelinux:9)
	$(eval PKG_SUPPORTED_ARCHS = x86_64 aarch64 arm64)

.PHONY: pkg-info-static
pkg-info-static:
	$(eval PKG_TYPE = static)
	$(eval PKG_DISTRO = static)
	$(eval PKG_SUITE =)
	$(eval PKG_BASE_IMAGE = debian:bullseye)
	$(eval PKG_SUPPORTED_ARCHS =)
