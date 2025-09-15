// Copyright 2022 Docker Packaging authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

variable "DISTROS" {
  description = "List of supported distros. Don't forget to update _distro-* target if you add/remove a distro."
  default = [
    "static",

    "debian11",
    "debian12",
    "debian13",
    "raspbian11",
    "raspbian12",
    "ubuntu2204",
    "ubuntu2404",
    "ubuntu2504",

    "almalinux8",
    "almalinux9",
    "centos9",
    "centos10",
    "fedora41",
    "fedora42",
    "oraclelinux8",
    "oraclelinux9",
    "rhel8",
    "rhel9",
    "rockylinux8",
    "rockylinux9"
  ]
}

variable "PKGS" {
  description = "List of packages to build from ./pkg directory. Don't forget to update _pkg-* target if you add/remove a package."
  default = [
    "buildx",
    "compose",
    "containerd",
    "credential-helpers",
    "docker-cli",
    "docker-engine",
    "model",
  ]
}

variable "DISTRO_NAME" {
  description = "Name of the distro."
  default = null
}
variable "DISTRO_TYPE" {
  description = "Type of the distro. One of deb, rpm, static."
  default = null
}
variable "DISTRO_RELEASE" {
  description = "Distro release name."
  default = null
}
variable "DISTRO_ID" {
  description = "Distro ID, e.g. 11 for debian11, 12 for debian12, etc."
  default = null
}
variable "DISTRO_SUITE" {
  description = "Distro suite name, e.g. bullseye for debian11, bookworm for debian12, etc."
  default = null
}
variable "DISTRO_IMAGE" {
  description = "Distro image to use for building packages."
  default = null
}

variable "PKG_NAME" {
  description = "Name of the package to build."
  default = null
}
variable "PKG_REPO" {
  description = "Repository URL of the package to build."
  default = null
}
variable "PKG_REF" {
  description = "Reference (branch, tag, commit) of the package to build."
  default = null
}
variable "PKG_VENDOR" {
  description = "Name of the vendor/maintainer of the package (only for linux packages)."
  default = "Docker"
}

variable "PKG_PACKAGER" {
  description = "Name of the company that produced the package (only for linux packages)."
  default = "Docker <support@docker.com>"
}

variable "PKG_DEB_BUILDFLAGS" {
  description = "Flags to pass to dpkg-buildpackage."
  default = "-b -uc"
}
variable "PKG_DEB_REVISION" {
  description = "Revision of the package to build, used for debian packages. Include an extra .0 in the version, in case we ever would have to re-build an already published release with a packaging-only change."
  default = "0"
}
variable "PKG_DEB_EPOCH" {
  description = "Epoch of the package to build, used for debian packages. This is used to allow mistakes in the version numbers of older versions of a package, and also a package's previous version numbering schemes, to be left behind. Should be enforced per package and not globally."
  default = null
}

variable "PKG_RPM_BUILDFLAGS" {
  description = "Flags to pass to rpmbuild."
  default = "-bb"
}
# rpm "Release:" field ($rpmRelease) is used to set the "_release" macro, which
# is an incremental number for builds of the same release (Version: / #rpmVersion)
# - Version: 0   : Package was built, but no matching upstream release (e.g., can be used for "nightly" builds)
# - Version: 1   : Package was built for an upstream (pre)release version
# - Version: > 1 : Only to be used for packaging-only changes (new package built for a version for which a package was already built/released)
variable "PKG_RPM_RELEASE" {
  description = "Release of the package to build, used for rpm packages. This to set the _release macro, which is an incremental number for builds of the same release (Version: / #rpmVersion)."
  default = null
}

variable "NIGHTLY_BUILD" {
  description = "Set to 1 to enforce nightly build."
  default = null
}

variable "GO_IMAGE" {
  description = "Go image to use for building packages."
  default = "golang"
}
variable "GO_VERSION" {
  description = "Go version to use for building packages."
  default = "1.24.7"
}
variable "GO_IMAGE_VARIANT" {
  description = "Go image variant to use for building packages."
  default = "bookworm"
}

variable "LOCAL_PLATFORM" {
  description = "Set to the current platform's default platform specification to build only for the local platform. If null, all platforms for the distro and package will be built."
  default = null
}

variable "BUILD_CACHE_REGISTRY_SLUG" {
  description = "Slug for the registry cache exporter."
  default = "dockereng/packaging-cache"
}
variable "BUILD_CACHE_REGISTRY_PUSH" {
  description = "Set to 1 to enable pushing to the registry cache exporter."
  default = ""
}

#
# distros configurations
#

target "_distro-static" {
  args = {
    DISTRO_NAME = ""
    DISTRO_TYPE = "static"
    DISTRO_RELEASE = "static"
    DISTRO_ID = ""
    DISTRO_SUITE = ""
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "debian:bookworm"
    TEST_ONLY = "0"
  }
}

target "_distro-debian11" {
  args = {
    DISTRO_NAME = "debian11"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "debian"
    DISTRO_ID = "11"
    DISTRO_SUITE = "bullseye"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "debian:bullseye"
    TEST_ONLY = "0"
  }
}

target "_distro-debian12" {
  args = {
    DISTRO_NAME = "debian12"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "debian"
    DISTRO_ID = "12"
    DISTRO_SUITE = "bookworm"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "debian:bookworm"
    TEST_ONLY = "0"
  }
}

target "_distro-debian13" {
  args = {
    DISTRO_NAME = "debian13"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "debian"
    DISTRO_ID = "13"
    DISTRO_SUITE = "trixie"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "debian:trixie"
    TEST_ONLY = "0"
  }
}

target "_distro-raspbian11" {
  args = {
    DISTRO_NAME = "raspbian11"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "raspbian"
    DISTRO_ID = "11"
    DISTRO_SUITE = "bullseye"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "balenalib/rpi-raspbian:bullseye"
    TEST_ONLY = "0"
  }
}

target "_distro-raspbian12" {
  args = {
    DISTRO_NAME = "raspbian12"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "raspbian"
    DISTRO_ID = "12"
    DISTRO_SUITE = "bookworm"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "balenalib/rpi-raspbian:bookworm"
    TEST_ONLY = "0"
  }
}

target "_distro-ubuntu2204" {
  args = {
    DISTRO_NAME = "ubuntu2204"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "ubuntu"
    DISTRO_ID = "22.04"
    DISTRO_SUITE = "jammy"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "ubuntu:jammy"
    TEST_ONLY = "0"
  }
}

target "_distro-ubuntu2404" {
  args = {
    DISTRO_NAME = "ubuntu2404"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "ubuntu"
    DISTRO_ID = "24.04"
    DISTRO_SUITE = "noble"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "ubuntu:noble"
    TEST_ONLY = "0"
  }
}

target "_distro-ubuntu2504" {
  args = {
    DISTRO_NAME = "ubuntu2504"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "ubuntu"
    DISTRO_ID = "25.04"
    DISTRO_SUITE = "plucky"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "ubuntu:plucky"
    TEST_ONLY = "0"
  }
}

target "_distro-almalinux8" {
  args = {
    DISTRO_NAME = "almalinux8"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "almalinux"
    DISTRO_ID = "8"
    DISTRO_SUITE = "8"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "almalinux:8"
    TEST_ONLY = "1"
  }
}

target "_distro-almalinux9" {
  args = {
    DISTRO_NAME = "almalinux9"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "almalinux"
    DISTRO_ID = "9"
    DISTRO_SUITE = "9"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "almalinux:9"
    TEST_ONLY = "1"
  }
}

target "_distro-centos9" {
  args = {
    DISTRO_NAME = "centos9"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "centos"
    DISTRO_ID = "9"
    DISTRO_SUITE = "9"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "quay.io/centos/centos:stream9"
    TEST_ONLY = "0"
  }
}

target "_distro-centos10" {
  args = {
    DISTRO_NAME = "centos10"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "centos"
    DISTRO_ID = "10"
    DISTRO_SUITE = "10"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "quay.io/centos/centos:stream10"
    TEST_ONLY = "0"
  }
}

target "_distro-fedora41" {
  args = {
    DISTRO_NAME = "fedora41"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "fedora"
    DISTRO_ID = "41"
    DISTRO_SUITE = "41"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "fedora:41"
    TEST_ONLY = "0"
  }
}

target "_distro-fedora42" {
  args = {
    DISTRO_NAME = "fedora42"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "fedora"
    DISTRO_ID = "42"
    DISTRO_SUITE = "42"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "fedora:42"
    TEST_ONLY = "0"
  }
}

target "_distro-oraclelinux8" {
  args = {
    DISTRO_NAME = "oraclelinux8"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "oraclelinux"
    DISTRO_ID = "8"
    DISTRO_SUITE = "8"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "oraclelinux:8"
    TEST_ONLY = "1"
  }
}

target "_distro-oraclelinux9" {
  args = {
    DISTRO_NAME = "oraclelinux9"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "oraclelinux"
    DISTRO_ID = "9"
    DISTRO_SUITE = "9"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "oraclelinux:9"
    TEST_ONLY = "1"
  }
}

target "_distro-rhel8" {
  args = {
    DISTRO_NAME = "rhel8"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "rhel"
    DISTRO_ID = "8"
    DISTRO_SUITE = "8"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "registry.access.redhat.com/ubi8/ubi"
    TEST_ONLY = "0"
  }
}

target "_distro-rhel9" {
  args = {
    DISTRO_NAME = "rhel9"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "rhel"
    DISTRO_ID = "9"
    DISTRO_SUITE = "9"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "registry.access.redhat.com/ubi9/ubi"
    TEST_ONLY = "0"
  }
}

target "_distro-rockylinux8" {
  args = {
    DISTRO_NAME = "rockylinux8"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "rockylinux"
    DISTRO_ID = "8"
    DISTRO_SUITE = "8"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "rockylinux/rockylinux:8"
    TEST_ONLY = "1"
  }
}

target "_distro-rockylinux9" {
  args = {
    DISTRO_NAME = "rockylinux9"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "rockylinux"
    DISTRO_ID = "9"
    DISTRO_SUITE = "9"
    DISTRO_IMAGE = DISTRO_IMAGE != null && DISTRO_IMAGE != "" ? DISTRO_IMAGE : "rockylinux/rockylinux:9"
    TEST_ONLY = "1"
  }
}

# Returns the list of supported platforms for a given distro and package.
# The result is the intersection of the platforms supported by the distro
# and the platforms supported by the package. Except for static distro,
# where we return all the platforms supported by the package as we are
# doing cross-compilation.
function "distroPlatforms" {
  params = [distro, pkg]
  result = distro == "static" ? pkgPlatforms(pkg) : setsubtract(
    setintersection(
      lookup({
        static = pkgPlatforms(pkg)

        debian11 = ["linux/386", "linux/amd64", "linux/arm64", "linux/arm/v7", "linux/mips64le", "linux/ppc64le", "linux/s390x"]
        debian12 = ["linux/386", "linux/amd64", "linux/arm64", "linux/arm/v7", "linux/mips64le", "linux/ppc64le", "linux/s390x"]
        debian13 = ["linux/386", "linux/amd64", "linux/arm64", "linux/arm/v7", "linux/mips64le", "linux/ppc64le", "linux/riscv64", "linux/s390x"]
        raspbian11 = ["linux/arm/v7"]
        raspbian12 = ["linux/arm/v7"]
        ubuntu2204 = ["linux/amd64", "linux/arm64", "linux/arm/v7", "linux/ppc64le", "linux/s390x"]
        ubuntu2404 = ["linux/amd64", "linux/arm64", "linux/arm/v7", "linux/ppc64le", "linux/riscv64", "linux/s390x"]
        ubuntu2504 = ["linux/amd64", "linux/arm64", "linux/arm/v7", "linux/ppc64le", "linux/riscv64", "linux/s390x"]

        almalinux8 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        almalinux9 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        centos9 = ["linux/amd64", "linux/arm64", "linux/ppc64le"]
        centos10 = ["linux/amd64", "linux/arm64", "linux/ppc64le"]
        fedora41 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        fedora42 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        oraclelinux8 = ["linux/amd64", "linux/arm64"]
        oraclelinux9 = ["linux/amd64", "linux/arm64"]
        rhel8 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        rhel9 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        rockylinux8 = ["linux/amd64", "linux/arm64"]
        rockylinux9 = ["linux/amd64", "linux/arm64"]
      }, distro, []),
      pkgPlatforms(pkg)
    ),
    # FIXME: add linux/ppc64le when a remote PowerPC instance is available (too slow with QEMU)
    # FIXME: add linux/riscv64 when a remote RISC-V instance is available (too slow with QEMU)
    # FIXME: add linux/s390x when a remote LinuxONE instance is reachable again (too slow with QEMU)
    ["linux/ppc64le", "linux/riscv64", "linux/s390x"]
  )
}

# Returns the list of secrets to use for a given distro.
function "distroSecrets" {
  params = [distro]
  result = length(regexall("^rhel", distro)) > 0 ? ["type=env,id=RH_USER,env=RH_USER", "type=env,id=RH_PASS,env=RH_PASS"] : []
}

#
# pkgs configurations
#

target "_pkg-buildx" {
  args = {
    PKG_NAME = PKG_NAME != null && PKG_NAME != "" ? PKG_NAME : "docker-buildx-plugin"
    PKG_REPO = PKG_REPO != null && PKG_REPO != "" ? PKG_REPO : "https://github.com/docker/buildx.git"
    PKG_REF = PKG_REF != null && PKG_REF != "" ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null && GO_VERSION != "" ? GO_VERSION : "1.24.7" # https://github.com/docker/buildx/blob/0c747263ef1426f5fa217fcdb616eddf33da6c2d/Dockerfile#L3
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null && GO_IMAGE_VARIANT != "" ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null && PKG_DEB_EPOCH != "" ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-compose" {
  args = {
    PKG_NAME = PKG_NAME != null && PKG_NAME != "" ? PKG_NAME : "docker-compose-plugin"
    PKG_REPO = PKG_REPO != null && PKG_REPO != "" ? PKG_REPO : "https://github.com/docker/compose.git"
    PKG_REF = PKG_REF != null && PKG_REF != "" ? PKG_REF : "main"
    GO_VERSION = GO_VERSION != null && GO_VERSION != "" ? GO_VERSION : "1.23.12" # https://github.com/docker/compose/blob/c2cb0aef6bbbe1afc8c9e81267621655ac90c5f6/Dockerfile#L18
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null && GO_IMAGE_VARIANT != "" ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null && PKG_DEB_EPOCH != "" ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-containerd" {
  args = {
    PKG_NAME = PKG_NAME != null && PKG_NAME != "" ? PKG_NAME : "containerd.io"
    PKG_REPO = PKG_REPO != null && PKG_REPO != "" ? PKG_REPO : "https://github.com/containerd/containerd.git"
    PKG_REF = PKG_REF != null && PKG_REF != "" ? PKG_REF : "main"
    GO_VERSION = GO_VERSION != null && GO_VERSION != "" ? GO_VERSION : "1.24.7" # https://github.com/containerd/containerd/blame/822fb144732946f2a6f7998bfe748ed175674ade/.github/workflows/release.yml#L16
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null && GO_IMAGE_VARIANT != "" ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null && PKG_DEB_EPOCH != "" ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-credential-helpers" {
  args = {
    PKG_NAME = PKG_NAME != null && PKG_NAME != "" ? PKG_NAME : "docker-credential-helpers"
    PKG_REPO = PKG_REPO != null && PKG_REPO != "" ? PKG_REPO : "https://github.com/docker/docker-credential-helpers.git"
    PKG_REF = PKG_REF != null && PKG_REF != "" ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null && GO_VERSION != "" ? GO_VERSION : "1.23.12" # https://github.com/docker/docker-credential-helpers/blob/f9d3010165b642df37215b1be945552f2c6f0e3b/Dockerfile#L3
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null && GO_IMAGE_VARIANT != "" ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null && PKG_DEB_EPOCH != "" ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-docker-cli" {
  args = {
    PKG_NAME = PKG_NAME != null && PKG_NAME != "" ? PKG_NAME : "docker-ce-cli"
    PKG_REPO = PKG_REPO != null && PKG_REPO != "" ? PKG_REPO : "https://github.com/docker/cli.git"
    PKG_REF = PKG_REF != null && PKG_REF != "" ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null && GO_VERSION != "" ? GO_VERSION : "1.24.7" # https://github.com/docker/cli/blob/d16defd9e237a02e4e8b8710d9ce4a15472e60c8/Dockerfile#L11
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null && GO_IMAGE_VARIANT != "" ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null && PKG_DEB_EPOCH != "" ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-docker-engine" {
  args = {
    PKG_NAME = PKG_NAME != null && PKG_NAME != "" ? PKG_NAME : "docker-ce"
    PKG_REPO = PKG_REPO != null && PKG_REPO != "" ? PKG_REPO : "https://github.com/docker/docker.git"
    PKG_REF = PKG_REF != null && PKG_REF != "" ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null && GO_VERSION != "" ? GO_VERSION : "1.24.7" # https://github.com/moby/moby/blob/4b978319922166bab9116b3e60e716a62b9cf130/Dockerfile#L3
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null && GO_IMAGE_VARIANT != "" ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null && PKG_DEB_EPOCH != "" ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-model" {
  args = {
    PKG_NAME = PKG_NAME != null && PKG_NAME != "" ? PKG_NAME : "docker-model-plugin"
    PKG_REPO = PKG_REPO != null && PKG_REPO != "" ? PKG_REPO : "https://github.com/docker/model-cli.git"
    PKG_REF = PKG_REF != null && PKG_REF != "" ? PKG_REF : "main"
    GO_VERSION = GO_VERSION != null && GO_VERSION != "" ? GO_VERSION : "1.24.7" # https://github.com/docker/model-cli/blob/301126afc8ef4b8330de56db5d2889ddbc978022/Dockerfile#L3
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null && GO_IMAGE_VARIANT != "" ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null && PKG_DEB_EPOCH != "" ? PKG_DEB_EPOCH : "5"
  }
}

# Returns the list of supported platforms for a given package.
function "pkgPlatforms" {
  params = [pkg]
  result = lookup({
    # https://github.com/docker/buildx/blob/0c747263ef1426f5fa217fcdb616eddf33da6c2d/docker-bake.hcl#L156-L174
    buildx = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/riscv64", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/docker/compose/blob/c626befee1596abcc74578cb10dd96ae1667f76f/docker-bake.hcl#L112-L124
    compose = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/riscv64", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/containerd/containerd/blob/87742bd35f6ddc47c638a448c271b7ccf8df9010/.github/workflows/ci.yml#L145-L165
    # https://github.com/containerd/containerd/blob/87742bd35f6ddc47c638a448c271b7ccf8df9010/.github/workflows/ci.yml#L135-L137
    containerd = ["linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/s390x", "windows/amd64", "windows/arm64", "windows/arm/v7"]
    # https://github.com/docker/docker-credential-helpers/blob/f9d3010165b642df37215b1be945552f2c6f0e3b/docker-bake.hcl#L56-L66
    credential-helpers = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/s390x", "windows/amd64"]
    # https://github.com/docker/cli/blob/84038691220e7ba3329a177e4e3357b4ee0e3a52/docker-bake.hcl#L30-L42
    docker-cli = ["darwin/amd64", "darwin/arm64", "linux/386", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/riscv64", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/moby/moby/blob/83264918d3e1c61341511e360a7277150b914b3f/docker-bake.hcl#L82-L91
    docker-engine = ["linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/docker/model-cli/blob/301126afc8ef4b8330de56db5d2889ddbc978022/Makefile#L36-L40
    model = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm64", "linux/arm/v7", "windows/amd64", "windows/arm64"]
  }, pkg, [])
}

#
#
#

target "_common" {
  args = {
    BUILDKIT_MULTI_PLATFORM = 1
    NIGHTLY_BUILD = NIGHTLY_BUILD
    GO_IMAGE = GO_IMAGE
    GO_VERSION = GO_VERSION
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT
    PKG_NAME = PKG_NAME
    PKG_REPO = PKG_REPO
    PKG_REF = PKG_REF
    PKG_VENDOR = PKG_VENDOR
    PKG_PACKAGER = PKG_PACKAGER
    PKG_DEB_BUILDFLAGS = PKG_DEB_BUILDFLAGS
    PKG_DEB_REVISION = PKG_DEB_REVISION
    PKG_DEB_EPOCH = PKG_DEB_EPOCH
    PKG_RPM_BUILDFLAGS = PKG_RPM_BUILDFLAGS
    PKG_RPM_RELEASE = PKG_RPM_RELEASE
  }
}

# Special target: https://github.com/docker/metadata-action#bake-definition
target "meta-helper" {
  tags = ["dockereng/packaging:local"]
}

group "default" {
  targets = ["validate"]
}

target "pkg" {
  name = "pkg-${pkg}-${distro}"
  description = "Build ${pkg} package for ${distro}"
  inherits = ["_common", "_distro-${distro}", "_pkg-${pkg}"]
  matrix = {
    pkg = PKGS
    distro = DISTROS
  }
  context = "./pkg/${pkg}"
  contexts = {
    scripts = "./hack/scripts"
  }
  output = ["type=local,dest=./bin/pkg/${pkg}/${distro}"]
  # BAKE_LOCAL_PLATFORM is a built-in var returning the current platform's
  # default platform specification: https://docs.docker.com/build/customize/bake/file-definition/#built-in-variables
  platforms = LOCAL_PLATFORM != null ? [BAKE_LOCAL_PLATFORM] : distroPlatforms(distro, pkg)
  secret = distroSecrets(distro)
  attest = [
    "type=sbom",
    "type=provenance,mode=max"
  ]
}

target "verify" {
  name = "verify-${pkg}-${distro}"
  description = "Verify ${pkg} package for ${distro}"
  inherits = ["_common", "_distro-${distro}", "_pkg-${pkg}"]
  matrix = {
    pkg = PKGS
    distro = DISTROS
  }
  context = "./pkg/${pkg}"
  dockerfile = "verify.Dockerfile"
  contexts = {
    scripts = "./hack/scripts"
    bin = "./bin/pkg/${pkg}/${distro}"
  }
  no-cache = true
  output = ["type=cacheonly"]
}

# Create release image by using ./bin folder as named context. Make sure all
# pkg targets are called before releasing
target "release" {
  name = "release-${pkg}"
  description = "Release ${pkg} package"
  inherits = ["_common", "meta-helper", "_pkg-${pkg}"]
  matrix = {
    pkg = PKGS
  }
  dockerfile = "./hack/release.Dockerfile"
  contexts = {
    bin = "./bin/pkg/${pkg}"
  }
  platforms = pkgPlatforms(pkg)
}

target "metadata" {
  name = "metadata-${pkg}"
  description = "Generate metadata for ${pkg} package"
  inherits = ["_common", "_pkg-${pkg}"]
  matrix = {
    pkg = PKGS
  }
  context = "./pkg/${pkg}"
  contexts = {
    scripts = "./hack/scripts"
  }
  target = "metadata"
  output = ["./bin/pkg/${pkg}"]
  args = {
    BUILDKIT_MULTI_PLATFORM = 0
  }
}

group "validate" {
  targets = ["license-validate"]
}

target "license-validate" {
  target = "license-validate"
  output = ["type=cacheonly"]
}

target "license-update" {
  target = "license-update"
  output = ["."]
}
