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

# Sets the docker cli repo. Will be used to clone the repo at
# DOCKER_CLI_VERSION ref to include the README.md and LICENSE for the
# static packages and also create version string.
variable "DOCKER_CLI_REPO" {
  default = "https://github.com/docker/cli.git"
}

# Sets the docker cli helpers version to build from source.
variable "DOCKER_CLI_VERSION" {
  default = "v20.10.17"
}

# Sets Go image, version and variant to use for building
variable "GO_IMAGE" {
  default = ""
}
variable "GO_VERSION" {
  default = ""
}
variable "GO_IMAGE_VARIANT" {
  default = ""
}

# Sets the pkg name.
variable "PKG_NAME" {
  default = "docker-ce-cli"
}

# Sets the list of package types to build: apk, deb, rpm or static
variable "PKG_TYPE" {
  default = "static"
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

# deb specific, see vars.mk for more details
variable "PKG_DEB_BUILDFLAGS" {
  default = "-b -uc"
}
variable "PKG_DEB_REVISION" {
  default = "0"
}
variable "PKG_DEB_EPOCH" {
  default = "5"
}

# rpm specific, see vars.mk for more details
variable "PKG_RPM_BUILDFLAGS" {
  default = "-bb"
}
variable "PKG_RPM_RELEASE" {
  default = "1"
}

# Defines the output folder
variable "DESTDIR" {
  default = ""
}
function "bindir" {
  params = [defaultdir]
  result = DESTDIR != "" ? DESTDIR : "./bin/${defaultdir}"
}

# Defines cache scope for GitHub Actions cache exporter
variable "BUILD_CACHE_SCOPE" {
  default = ""
}

group "default" {
  targets = ["pkg"]
}

target "_common" {
  inherits = ["_pkg-${PKG_RELEASE}"]
  args = {
    BUILDKIT_MULTI_PLATFORM = 1
    DOCKER_CLI_REPO = DOCKER_CLI_REPO
    DOCKER_CLI_VERSION = DOCKER_CLI_VERSION
    GO_IMAGE = GO_IMAGE
    GO_VERSION = GO_VERSION
    GO_IMAGE_VARIANT = GO_IMAGE_VARIANT
    PKG_NAME = PKG_NAME
    PKG_VENDOR = PKG_VENDOR
    PKG_PACKAGER = PKG_PACKAGER
    PKG_DEB_BUILDFLAGS = PKG_DEB_BUILDFLAGS
    PKG_DEB_REVISION = PKG_DEB_REVISION
    PKG_DEB_EPOCH = PKG_DEB_EPOCH
    PKG_RPM_BUILDFLAGS = PKG_RPM_BUILDFLAGS
    PKG_RPM_RELEASE = PKG_RPM_RELEASE
  }
  cache-from = [BUILD_CACHE_SCOPE != "" ? "type=gha,scope=${BUILD_CACHE_SCOPE}-${PKG_RELEASE}" : ""]
  cache-to = [BUILD_CACHE_SCOPE != "" ? "type=gha,scope=${BUILD_CACHE_SCOPE}-${PKG_RELEASE}" : ""]
}

target "_platforms" {
  platforms = [
    "darwin/amd64",
    "darwin/arm64",
    "linux/386",
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm64",
    "linux/ppc64le",
    "linux/s390x",
    "windows/amd64"
  ]
}

# $ PKG_RELEASE=debian11 docker buildx bake pkg
# $ docker buildx bake --set *.platform=linux/amd64 --set *.output=./bin pkg
target "pkg" {
  inherits = ["_common"]
  target = "pkg"
  output = [bindir(PKG_RELEASE)]
}

# Same as pkg but for all supported platforms
target "pkg-cross" {
  inherits = ["pkg", "_platforms"]
}

# Special target: https://github.com/docker/metadata-action#bake-definition
target "meta-helper" {
  tags = ["dockereng/packaging:docker-cli-local"]
}

# Create release image by using ./bin folder as named context. Therefore
# pkg-cross target must be run before using this target:
# $ PKG_RELEASE=debian11 docker buildx bake pkg-cross
# $ docker buildx bake release --push --set *.tags=docker/packaging:docker-cli-v20.10.17
target "release" {
  inherits = ["meta-helper", "_platforms"]
  dockerfile = "../../common/release.Dockerfile"
  target = "release"
  contexts = {
    bin-folder = "./bin"
  }
}
