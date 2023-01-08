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

variable "PKG_RELEASE" {
  default = ""
}
variable "PKG_TYPE" {
  default = ""
}
variable "PKG_DISTRO" {
  default = ""
}
variable "PKG_SUITE" {
  default = ""
}
variable "PKG_BASE_IMAGE" {
  default = ""
}

target "_pkg-alpine314" {
  args = {
    PKG_RELEASE = "alpine314"
    PKG_TYPE = "apk"
    PKG_DISTRO = "alpine"
    PKG_SUITE = "3.14"
    PKG_BASE_IMAGE = "alpine:3.14"
  }
}

target "_pkg-alpine315" {
  args = {
    PKG_RELEASE = "alpine315"
    PKG_TYPE = "apk"
    PKG_DISTRO = "alpine"
    PKG_SUITE = "3.15"
    PKG_BASE_IMAGE = "alpine:3.15"
  }
}

target "_pkg-alpine316" {
  args = {
    PKG_RELEASE = "alpine316"
    PKG_TYPE = "apk"
    PKG_DISTRO = "alpine"
    PKG_SUITE = "3.16"
    PKG_BASE_IMAGE = "alpine:3.16"
  }
}

target "_pkg-debian10" {
  args = {
    PKG_RELEASE = "debian10"
    PKG_TYPE = "deb"
    PKG_DISTRO = "debian"
    PKG_SUITE = "buster"
    PKG_BASE_IMAGE = "debian:buster"
  }
}

target "_pkg-debian11" {
  args = {
    PKG_RELEASE = "debian11"
    PKG_TYPE = "deb"
    PKG_DISTRO = "debian"
    PKG_SUITE = "bullseye"
    PKG_BASE_IMAGE = "debian:bullseye"
  }
}

target "_pkg-raspbian10" {
  args = {
    PKG_RELEASE = "raspbian10"
    PKG_TYPE = "deb"
    PKG_DISTRO = "raspbian"
    PKG_SUITE = "buster"
    PKG_BASE_IMAGE = "balenalib/rpi-raspbian:buster"
  }
}

target "_pkg-raspbian11" {
  args = {
    PKG_RELEASE = "raspbian11"
    PKG_TYPE = "deb"
    PKG_DISTRO = "raspbian"
    PKG_SUITE = "bullseye"
    PKG_BASE_IMAGE = "balenalib/rpi-raspbian:bullseye"
  }
}

target "_pkg-ubuntu1804" {
  args = {
    PKG_RELEASE = "ubuntu1804"
    PKG_TYPE = "deb"
    PKG_DISTRO = "ubuntu"
    PKG_SUITE = "bionic"
    PKG_BASE_IMAGE = "ubuntu:bionic"
  }
}

target "_pkg-ubuntu2004" {
  args = {
    PKG_RELEASE = "ubuntu2004"
    PKG_TYPE = "deb"
    PKG_DISTRO = "ubuntu"
    PKG_SUITE = "focal"
    PKG_BASE_IMAGE = "ubuntu:focal"
  }
}

target "_pkg-ubuntu2204" {
  args = {
    PKG_RELEASE = "ubuntu2204"
    PKG_TYPE = "deb"
    PKG_DISTRO = "ubuntu"
    PKG_SUITE = "jammy"
    PKG_BASE_IMAGE = "ubuntu:jammy"
  }
}

target "_pkg-ubuntu2210" {
  args = {
    PKG_RELEASE = "ubuntu2210"
    PKG_TYPE = "deb"
    PKG_DISTRO = "ubuntu"
    PKG_SUITE = "kinetic"
    PKG_BASE_IMAGE = "ubuntu:kinetic"
  }
}

target "_pkg-centos7" {
  args = {
    PKG_RELEASE = "centos7"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "centos"
    PKG_SUITE = "7"
    PKG_BASE_IMAGE = "centos:7"
  }
}

target "_pkg-centos8" {
  args = {
    PKG_RELEASE = "centos8"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "centos"
    PKG_SUITE = "8"
    PKG_BASE_IMAGE = "quay.io/centos/centos:stream8"
  }
}

target "_pkg-centos9" {
  args = {
    PKG_RELEASE = "centos9"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "centos"
    PKG_SUITE = "9"
    PKG_BASE_IMAGE = "quay.io/centos/centos:stream9"
  }
}

target "_pkg-fedora36" {
  args = {
    PKG_RELEASE = "fedora36"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "fedora"
    PKG_SUITE = "36"
    PKG_BASE_IMAGE = "fedora:36"
  }
}

target "_pkg-fedora37" {
  args = {
    PKG_RELEASE = "fedora37"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "fedora"
    PKG_SUITE = "37"
    PKG_BASE_IMAGE = "fedora:37"
  }
}

target "_pkg-oraclelinux7" {
  args = {
    PKG_RELEASE = "oraclelinux7"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "oraclelinux"
    PKG_SUITE = "7"
    PKG_BASE_IMAGE = "oraclelinux:7"
  }
}

target "_pkg-oraclelinux8" {
  args = {
    PKG_RELEASE = "oraclelinux8"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "oraclelinux"
    PKG_SUITE = "8"
    PKG_BASE_IMAGE = "oraclelinux:8"
  }
}

target "_pkg-oraclelinux9" {
  args = {
    PKG_RELEASE = "oraclelinux9"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "oraclelinux"
    PKG_SUITE = "9"
    PKG_BASE_IMAGE = "oraclelinux:9"
  }
}

target "_pkg-static" {
  args = {
    PKG_RELEASE = ""
    PKG_TYPE = "static"
    PKG_DISTRO = "static"
    PKG_SUITE = ""
    PKG_BASE_IMAGE = "debian:bullseye"
  }
}
