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
PKG_DEB_RELEASES ?= debian10 debian11 debian12 ubuntu2004 ubuntu2204 raspbian10 raspbian11 raspbian12
PKG_RPM_RELEASES ?= centos9 fedora37 fedora38 fedora39 oraclelinux7 oraclelinux8 oraclelinux9

# PKG_SUPPORTED_PLATFORMS could be replaced by:
# docker buildx imagetools inspect centos:7 --format "{{json .Manifest}}" | jq -r '.manifests[] | "\(.platform.os)/\(.platform.architecture)/\(.platform.variant)"' | sed 's#/null$##' | tr '\n' ',' | sed 's#,$##'

.PHONY: pkg-apk-releases
pkg-apk-releases:
	$(eval PKG_RELEASES = $(PKG_APK_RELEASES))

.PHONY: pkg-deb-releases
pkg-deb-releases:
	$(eval PKG_RELEASES = $(PKG_DEB_RELEASES))

.PHONY: pkg-rpm-releases
pkg-rpm-releases:
	$(eval PKG_RELEASES = $(PKG_RPM_RELEASES))

.PHONY: pkg-static-releases
pkg-static-releases:
	$(eval PKG_RELEASES = static)

.PHONY: pkg-info-alpine314
pkg-info-alpine314:
	$(eval PKG_TYPE = apk)
	$(eval PKG_DISTRO = alpine)
	$(eval PKG_DISTRO_ID = 3.14)
	$(eval PKG_DISTRO_SUITE = 3.14)
	$(eval PKG_BASE_IMAGE = alpine:3.14)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/386 linux/amd64 linux/arm64 linux/arm/v7 linux/arm/v6 linux/arm/v5 linux/ppc64le linux/s390x)

.PHONY: pkg-info-alpine315
pkg-info-alpine315:
	$(eval PKG_TYPE = apk)
	$(eval PKG_DISTRO = alpine)
	$(eval PKG_DISTRO_ID = 3.15)
	$(eval PKG_DISTRO_SUITE = 3.15)
	$(eval PKG_BASE_IMAGE = alpine:3.15)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/386 linux/amd64 linux/arm64 linux/arm/v7 linux/arm/v6 linux/arm/v5 linux/ppc64le linux/s390x)

.PHONY: pkg-info-alpine316
pkg-info-alpine316:
	$(eval PKG_TYPE = apk)
	$(eval PKG_DISTRO = alpine)
	$(eval PKG_DISTRO_ID = 3.16)
	$(eval PKG_DISTRO_SUITE = 3.16)
	$(eval PKG_BASE_IMAGE = alpine:3.16)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/386 linux/amd64 linux/arm64 linux/arm/v7 linux/arm/v6 linux/arm/v5 linux/ppc64le linux/s390x)

.PHONY: pkg-info-debian10
pkg-info-debian10:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = debian)
	$(eval PKG_DISTRO_ID = 10)
	$(eval PKG_DISTRO_SUITE = buster)
	$(eval PKG_BASE_IMAGE = debian:buster)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/386 linux/amd64 linux/arm64 linux/arm/v7)

.PHONY: pkg-info-debian11
pkg-info-debian11:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = debian)
	$(eval PKG_DISTRO_ID = 11)
	$(eval PKG_DISTRO_SUITE = bullseye)
	$(eval PKG_BASE_IMAGE = debian:bullseye)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/386 linux/amd64 linux/arm64 linux/arm/v5 linux/arm/v6 linux/arm/v7 linux/mips64le linux/ppc64le linux/s390x)

.PHONY: pkg-info-debian12
pkg-info-debian12:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = debian)
	$(eval PKG_DISTRO_ID = 12)
	$(eval PKG_DISTRO_SUITE = bookworm)
	$(eval PKG_BASE_IMAGE = debian:bookworm)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/386 linux/amd64 linux/arm64 linux/arm/v5 linux/arm/v6 linux/arm/v7 linux/mips64le linux/ppc64le linux/s390x)

.PHONY: pkg-info-raspbian10
pkg-info-raspbian10:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = raspbian)
	$(eval PKG_DISTRO_ID = 10)
	$(eval PKG_DISTRO_SUITE = buster)
	$(eval PKG_BASE_IMAGE = balenalib/rpi-raspbian:buster)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/arm/v7)

.PHONY: pkg-info-raspbian11
pkg-info-raspbian11:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = raspbian)
	$(eval PKG_DISTRO_ID = 11)
	$(eval PKG_DISTRO_SUITE = bullseye)
	$(eval PKG_BASE_IMAGE = balenalib/rpi-raspbian:bullseye)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/arm/v7)

.PHONY: pkg-info-raspbian12
pkg-info-raspbian12:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = raspbian)
	$(eval PKG_DISTRO_ID = 12)
	$(eval PKG_DISTRO_SUITE = bookworm)
	$(eval PKG_BASE_IMAGE = balenalib/rpi-raspbian:bookworm)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/arm/v7)

.PHONY: pkg-info-ubuntu2004
pkg-info-ubuntu2004:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = ubuntu)
	$(eval PKG_DISTRO_ID = 20.04)
	$(eval PKG_DISTRO_SUITE = focal)
	$(eval PKG_BASE_IMAGE = ubuntu:focal)
	@# FIXME: linux/riscv64 is not supported (golang base image does not support riscv64)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64 linux/arm/v7 linux/ppc64le linux/s390x)

.PHONY: pkg-info-ubuntu2204
pkg-info-ubuntu2204:
	$(eval PKG_TYPE = deb)
	$(eval PKG_DISTRO = ubuntu)
	$(eval PKG_DISTRO_ID = 22.04)
	$(eval PKG_DISTRO_SUITE = jammy)
	$(eval PKG_BASE_IMAGE = ubuntu:jammy)
	@# FIXME: linux/riscv64 is not supported (golang base image does not support riscv64)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64 linux/arm/v7 linux/ppc64le linux/s390x)

.PHONY: pkg-info-centos9
pkg-info-centos9:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = centos)
	$(eval PKG_DISTRO_ID = 9)
	$(eval PKG_DISTRO_SUITE = 9)
	$(eval PKG_BASE_IMAGE = quay.io/centos/centos:stream9)
	@# FIXME: packages look broken for linux/s390x on centos:stream9
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64 linux/ppc64le)

.PHONY: pkg-info-fedora37
pkg-info-fedora37:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = fedora)
	$(eval PKG_DISTRO_ID = 37)
	$(eval PKG_DISTRO_SUITE = 37)
	$(eval PKG_BASE_IMAGE = fedora:37)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64 linux/ppc64le linux/s390x)

.PHONY: pkg-info-fedora38
pkg-info-fedora38:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = fedora)
	$(eval PKG_DISTRO_ID = 38)
	$(eval PKG_DISTRO_SUITE = 38)
	$(eval PKG_BASE_IMAGE = fedora:38)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64 linux/ppc64le linux/s390x)

.PHONY: pkg-info-fedora39
pkg-info-fedora39:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = fedora)
	$(eval PKG_DISTRO_ID = 39)
	$(eval PKG_DISTRO_SUITE = 39)
	$(eval PKG_BASE_IMAGE = fedora:39)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64 linux/ppc64le linux/s390x)

.PHONY: pkg-info-oraclelinux7
pkg-info-oraclelinux7:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = oraclelinux)
	$(eval PKG_DISTRO_ID = 7)
	$(eval PKG_DISTRO_SUITE = 7)
	$(eval PKG_BASE_IMAGE = oraclelinux:7)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64)

.PHONY: pkg-info-oraclelinux8
pkg-info-oraclelinux8:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = oraclelinux)
	$(eval PKG_DISTRO_ID = 8)
	$(eval PKG_DISTRO_SUITE = 8)
	$(eval PKG_BASE_IMAGE = oraclelinux:8)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64)

.PHONY: pkg-info-oraclelinux9
pkg-info-oraclelinux9:
	$(eval PKG_TYPE = rpm)
	$(eval PKG_DISTRO = oraclelinux)
	$(eval PKG_DISTRO_ID = 9)
	$(eval PKG_DISTRO_SUITE = 9)
	$(eval PKG_BASE_IMAGE = oraclelinux:9)
	$(eval PKG_SUPPORTED_PLATFORMS = linux/amd64 linux/arm64)

.PHONY: pkg-info-static
pkg-info-static:
	$(eval PKG_TYPE = static)
	$(eval PKG_DISTRO = static)
	$(eval PKG_DISTRO_ID =)
	$(eval PKG_DISTRO_SUITE =)
	$(eval PKG_BASE_IMAGE = debian:bullseye)
	$(eval PKG_SUPPORTED_PLATFORMS =)
