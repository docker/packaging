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

# Sets the buildx repo. Will be used to clone the repo at BUILDX_VERSION ref
# to include the README.md and LICENSE for the static packages and also
# create version string.
variable "BUILDX_REPO" {
  default = "https://github.com/docker/buildx.git"
}

# Sets the buildx version to download the binary from GitHub Releases.
# If version starts with # it will build from source.
variable "BUILDX_VERSION" {
  default = "v0.9.1"
}

# Sets the pkg name.
variable "PKG_NAME" {
  default = "docker-buildx-plugin"
}

# Sets release flavor. See packages.hcl and packages.mk for more details.
variable "PKG_RELEASE" {
  default = "static"
}
target "_pkg-static" {
  args = {
    PKG_RELEASE = ""
    PKG_TYPE = "static"
  }
}

# Sets the vendor/maintainer name (only for linux packages)
variable "PKG_VENDOR" {
  default = "Docker"
}

# Sets the name of the company that produced the package (only for linux packages)
variable "PKG_PACKAGER" {
  default = "Docker <support@docker.com>"
}

# Include an extra `.0` in the version, in case we ever would have to re-build
# an already published release with a packaging-only change.
variable "PKG_REVISION" {
  default = "0"
}

# Defines the output folder
variable "DESTDIR" {
  default = ""
}
function "bindir" {
  params = [defaultdir]
  result = DESTDIR != "" ? DESTDIR : "./bin/${defaultdir}"
}

# Special target: https://github.com/docker/metadata-action#bake-definition
target "meta-helper" {
  tags = ["dockereng/packaging:buildx-local"]
}

group "default" {
  targets = ["pkg"]
}

target "_common" {
  inherits = ["_pkg-${PKG_RELEASE}"]
  args = {
    BUILDX_REPO = BUILDX_REPO
    BUILDX_VERSION = BUILDX_VERSION
    PKG_NAME = PKG_NAME
    PKG_VENDOR = PKG_VENDOR
    PKG_PACKAGER = PKG_PACKAGER
    PKG_REVISION = PKG_REVISION
  }
}

target "_platforms" {
  platforms = [
    "darwin/amd64",
    "darwin/arm64",
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64",
    "linux/ppc64le",
    "linux/riscv64",
    "linux/s390x",
    "windows/amd64",
    "windows/arm64"
  ]
}

# $ PKG_RELEASE=debian11 docker buildx bake pkg
# $ docker buildx bake --set *.platform=linux/amd64 --set *.output=./bin pkg
group "pkg" {
  targets = [substr(BUILDX_VERSION, 0, 1) == "#" ? "_pkg-build" : "_pkg-download"]
}

# Same as pkg but for all supported platforms
group "pkg-cross" {
  targets = [substr(BUILDX_VERSION, 0, 1) == "#" ? "_pkg-build-cross" : "_pkg-download-cross"]
}

# Create release image by using ./bin folder as named context. Therefore
# pkg-cross target must be run before using this target:
# $ PKG_RELEASE=debian11 docker buildx bake pkg-cross
# $ docker buildx bake release --push --set *.tags=docker/packaging:build-v0.9.1
target "release" {
  inherits = ["meta-helper", "_platforms"]
  target = "release"
  contexts = {
    bin-folder = "./bin"
  }
}

target "_pkg-download" {
  inherits = ["_common"]
  target = "pkg"
  platforms = ["local"]
  output = [bindir("local")]
}

target "_pkg-download-cross" {
  inherits = ["_pkg-download", "_platforms"]
  output = [bindir("cross")]
}

target "_pkg-build" {
  inherits = ["_pkg-download"]
  args = {
    MODE = "build"
    BUILDX_VERSION = trimprefix(BUILDX_VERSION, "#")
  }
  contexts = {
    build = "target:_build"
  }
  output = [bindir("local")]
}

target "_pkg-build-cross" {
  inherits = ["_pkg-download-cross"]
  args = {
    MODE = "build"
    BUILDX_VERSION = trimprefix(BUILDX_VERSION, "#")
  }
  contexts = {
    build = "target:_build-cross"
  }
  output = [bindir("cross")]
}

target "_build" {
  context = "${BUILDX_REPO}${BUILDX_VERSION}"
  args = {
    MODE = "build"
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
    BUILDKIT_MULTI_PLATFORM = 1
  }
  target = "binaries"
}

target "_build-cross" {
  inherits = ["build", "_platforms"]
}
