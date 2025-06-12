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
    "centos9",
    "fedora37",
    "fedora38",
    "fedora39",
    "oraclelinux8",
    "oraclelinux9"
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
    "sbom",
    "scan"
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
  default = "1.24.4"
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
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "debian:bookworm"
  }
}

target "_distro-debian11" {
  args = {
    DISTRO_NAME = "debian11"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "debian"
    DISTRO_ID = "11"
    DISTRO_SUITE = "bullseye"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "debian:bullseye"
  }
}

target "_distro-debian12" {
  args = {
    DISTRO_NAME = "debian12"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "debian"
    DISTRO_ID = "12"
    DISTRO_SUITE = "bookworm"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "debian:bookworm"
  }
}

target "_distro-debian13" {
  args = {
    DISTRO_NAME = "debian13"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "debian"
    DISTRO_ID = "13"
    DISTRO_SUITE = "trixie"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "debian:trixie"
  }
}

target "_distro-raspbian11" {
  args = {
    DISTRO_NAME = "raspbian11"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "raspbian"
    DISTRO_ID = "11"
    DISTRO_SUITE = "bullseye"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "balenalib/rpi-raspbian:bullseye"
  }
}

target "_distro-raspbian12" {
  args = {
    DISTRO_NAME = "raspbian12"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "raspbian"
    DISTRO_ID = "12"
    DISTRO_SUITE = "bookworm"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "balenalib/rpi-raspbian:bookworm"
  }
}

target "_distro-ubuntu2204" {
  args = {
    DISTRO_NAME = "ubuntu2204"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "ubuntu"
    DISTRO_ID = "22.04"
    DISTRO_SUITE = "jammy"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "ubuntu:jammy"
  }
}

target "_distro-ubuntu2404" {
  args = {
    DISTRO_NAME = "ubuntu2404"
    DISTRO_TYPE = "deb"
    DISTRO_RELEASE = "ubuntu"
    DISTRO_ID = "24.04"
    DISTRO_SUITE = "noble"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "ubuntu:noble"
  }
}

target "_distro-centos9" {
  args = {
    DISTRO_NAME = "centos9"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "centos"
    DISTRO_ID = "9"
    DISTRO_SUITE = "9"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "quay.io/centos/centos:stream9"
  }
}

target "_distro-fedora37" {
  args = {
    DISTRO_NAME = "fedora37"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "fedora"
    DISTRO_ID = "37"
    DISTRO_SUITE = "37"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "fedora:37"
  }
}

target "_distro-fedora38" {
  args = {
    DISTRO_NAME = "fedora38"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "fedora"
    DISTRO_ID = "38"
    DISTRO_SUITE = "38"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "fedora:38"
  }
}

target "_distro-fedora39" {
  args = {
    DISTRO_NAME = "fedora39"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "fedora"
    DISTRO_ID = "39"
    DISTRO_SUITE = "39"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "fedora:39"
  }
}

target "_distro-oraclelinux8" {
  args = {
    DISTRO_NAME = "oraclelinux8"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "oraclelinux"
    DISTRO_ID = "8"
    DISTRO_SUITE = "8"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "oraclelinux:8"
  }
}

target "_distro-oraclelinux9" {
  args = {
    DISTRO_NAME = "oraclelinux9"
    DISTRO_TYPE = "rpm"
    DISTRO_RELEASE = "oraclelinux"
    DISTRO_ID = "9"
    DISTRO_SUITE = "9"
    DISTRO_IMAGE = DISTRO_IMAGE != null ? DISTRO_IMAGE : "oraclelinux:9"
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
        centos9 = ["linux/amd64", "linux/arm64", "linux/ppc64le"]
        fedora37 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        fedora38 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        fedora39 = ["linux/amd64", "linux/arm64", "linux/ppc64le", "linux/s390x"]
        oraclelinux8 = ["linux/amd64", "linux/arm64"]
        oraclelinux9 = ["linux/amd64", "linux/arm64"]
      }, distro, []),
      pkgPlatforms(pkg)
    ),
    # FIXME: add linux/ppc64le when a remote PowerPC instance is available (too slow with QEMU)
    # FIXME: add linux/riscv64 when a remote RISC-V instance is available (too slow with QEMU)
    # FIXME: add linux/s390x when a remote LinuxONE instance is reachable again (too slow with QEMU)
    ["linux/ppc64le", "linux/riscv64", "linux/s390x"]
  )
}

#
# pkgs configurations
#

target "_pkg-buildx" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "docker-buildx-plugin"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/docker/buildx.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.24.4" # https://github.com/docker/buildx/blob/master/Dockerfile#L3
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-compose" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "docker-compose-plugin"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/docker/compose.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "main"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.23.8" # https://github.com/docker/compose/blob/main/Dockerfile#L18
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-containerd" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "containerd.io"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/containerd/containerd.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "main"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.24.3" # https://github.com/containerd/containerd/blob/main/.github/workflows/release.yml#L16
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-credential-helpers" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "docker-credential-helpers"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/docker/docker-credential-helpers.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.23.6" # https://github.com/docker/docker-credential-helpers/blob/master/Dockerfile#L3
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-docker-cli" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "docker-ce-cli"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/docker/cli.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.24.3" # https://github.com/docker/cli/blob/master/Dockerfile#L7
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-docker-engine" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "docker-ce"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/docker/docker.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "master"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.24.4" # https://github.com/moby/moby/blob/master/Dockerfile#L3
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bookworm"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-sbom" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "docker-sbom-plugin"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/docker/sbom-cli-plugin.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "main"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.18" # https://github.com/docker/sbom-cli-plugin/blob/main/.github/workflows/release.yaml#L12
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bullseye"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

target "_pkg-scan" {
  args = {
    PKG_NAME = PKG_NAME != null ? PKG_NAME : "docker-scan-plugin"
    PKG_REPO = PKG_REPO != null ? PKG_REPO : "https://github.com/docker/scan-cli-plugin.git"
    PKG_REF = PKG_REF != null ? PKG_REF : "main"
    GO_VERSION = GO_VERSION != null ? GO_VERSION : "1.19.10" # https://github.com/docker/scan-cli-plugin/blob/main/Dockerfile#L19
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT != null ? GO_IMAGE_VARIANT : "bullseye"
    PKG_DEB_EPOCH = PKG_DEB_EPOCH != null ? PKG_DEB_EPOCH : "5"
  }
}

# Returns the list of supported platforms for a given package.
function "pkgPlatforms" {
  params = [pkg]
  result = lookup({
    # https://github.com/docker/buildx/blob/master/docker-bake.hcl#L110-L122
    buildx = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/riscv64", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/docker/compose/blob/main/docker-bake.hcl#L95-L107
    compose = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/riscv64", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/containerd/containerd/blob/main/.github/workflows/ci.yml#L145-L165
    containerd = ["linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/s390x"]
    # https://github.com/docker/docker-credential-helpers/blob/master/docker-bake.hcl#L56-L66
    credential-helpers = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/s390x", "windows/amd64"]
    # https://github.com/docker/cli/blob/master/docker-bake.hcl#L30-L42
    docker-cli = ["darwin/amd64", "darwin/arm64", "linux/386", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/riscv64", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/moby/moby/blob/master/docker-bake.hcl#L93-L101
    docker-engine = ["linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64", "linux/ppc64le", "linux/s390x", "windows/amd64", "windows/arm64"]
    # https://github.com/docker/sbom-cli-plugin/blob/main/.goreleaser.yaml#L7-L13
    sbom = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm64", "windows/amd64", "windows/arm64"]
    # https://github.com/docker/scan-cli-plugin/blob/main/builder.Makefile#L63-L67
    scan = ["darwin/amd64", "darwin/arm64", "linux/amd64", "linux/arm64", "windows/amd64"]
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
