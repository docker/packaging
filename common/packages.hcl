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
variable "PKG_DISTRO_ID" {
  default = ""
}
variable "PKG_DISTRO_SUITE" {
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
    PKG_DISTRO_ID = "3.14"
    PKG_DISTRO_SUITE = "3.14"
    PKG_BASE_IMAGE = "alpine:3.14"
  }
}

target "_pkg-alpine315" {
  args = {
    PKG_RELEASE = "alpine315"
    PKG_TYPE = "apk"
    PKG_DISTRO = "alpine"
    PKG_DISTRO_ID = "3.15"
    PKG_DISTRO_SUITE = "3.15"
    PKG_BASE_IMAGE = "alpine:3.15"
  }
}

target "_pkg-alpine316" {
  args = {
    PKG_RELEASE = "alpine316"
    PKG_TYPE = "apk"
    PKG_DISTRO = "alpine"
    PKG_DISTRO_ID = "3.16"
    PKG_DISTRO_SUITE = "3.16"
    PKG_BASE_IMAGE = "alpine:3.16"
  }
}

target "_pkg-debian10" {
  args = {
    PKG_RELEASE = "debian10"
    PKG_TYPE = "deb"
    PKG_DISTRO = "debian"
    PKG_DISTRO_ID = "10"
    PKG_DISTRO_SUITE = "buster"
    PKG_BASE_IMAGE = "debian:buster"
  }
}

target "_pkg-debian11" {
  args = {
    PKG_RELEASE = "debian11"
    PKG_TYPE = "deb"
    PKG_DISTRO = "debian"
    PKG_DISTRO_ID = "11"
    PKG_DISTRO_SUITE = "bullseye"
    PKG_BASE_IMAGE = "debian:bullseye"
  }
}

target "_pkg-debian12" {
  args = {
    PKG_RELEASE = "debian12"
    PKG_TYPE = "deb"
    PKG_DISTRO = "debian"
    PKG_DISTRO_ID = "12"
    PKG_DISTRO_SUITE = "bookworm"
    PKG_BASE_IMAGE = "debian:bookworm"
  }
}

target "_pkg-raspbian10" {
  args = {
    PKG_RELEASE = "raspbian10"
    PKG_TYPE = "deb"
    PKG_DISTRO = "raspbian"
    PKG_DISTRO_ID = "10"
    PKG_DISTRO_SUITE = "buster"
    PKG_BASE_IMAGE = "balenalib/rpi-raspbian:buster"
  }
}

target "_pkg-raspbian11" {
  args = {
    PKG_RELEASE = "raspbian11"
    PKG_TYPE = "deb"
    PKG_DISTRO = "raspbian"
    PKG_DISTRO_ID = "11"
    PKG_DISTRO_SUITE = "bullseye"
    PKG_BASE_IMAGE = "balenalib/rpi-raspbian:bullseye"
  }
}

target "_pkg-raspbian12" {
  args = {
    PKG_RELEASE = "raspbian12"
    PKG_TYPE = "deb"
    PKG_DISTRO = "raspbian"
    PKG_DISTRO_ID = "12"
    PKG_DISTRO_SUITE = "bookworm"
    PKG_BASE_IMAGE = "balenalib/rpi-raspbian:bookworm"
  }
}

target "_pkg-ubuntu2004" {
  args = {
    PKG_RELEASE = "ubuntu2004"
    PKG_TYPE = "deb"
    PKG_DISTRO = "ubuntu"
    PKG_DISTRO_ID = "20.04"
    PKG_DISTRO_SUITE = "focal"
    PKG_BASE_IMAGE = "ubuntu:focal"
  }
}

target "_pkg-ubuntu2204" {
  args = {
    PKG_RELEASE = "ubuntu2204"
    PKG_TYPE = "deb"
    PKG_DISTRO = "ubuntu"
    PKG_DISTRO_ID = "22.04"
    PKG_DISTRO_SUITE = "jammy"
    PKG_BASE_IMAGE = "ubuntu:jammy"
  }
}

target "_pkg-centos8" {
  args = {
    PKG_RELEASE = "centos8"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "centos"
    PKG_DISTRO_ID = "8"
    PKG_DISTRO_SUITE = "8"
    PKG_BASE_IMAGE = "quay.io/centos/centos:stream8"
  }
}

target "_pkg-centos9" {
  args = {
    PKG_RELEASE = "centos9"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "centos"
    PKG_DISTRO_ID = "9"
    PKG_DISTRO_SUITE = "9"
    PKG_BASE_IMAGE = "quay.io/centos/centos:stream9"
  }
}

target "_pkg-fedora37" {
  args = {
    PKG_RELEASE = "fedora37"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "fedora"
    PKG_DISTRO_ID = "37"
    PKG_DISTRO_SUITE = "37"
    PKG_BASE_IMAGE = "fedora:37"
  }
}

target "_pkg-fedora38" {
  args = {
    PKG_RELEASE = "fedora38"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "fedora"
    PKG_DISTRO_ID = "38"
    PKG_DISTRO_SUITE = "38"
    PKG_BASE_IMAGE = "fedora:38"
  }
}

target "_pkg-fedora39" {
  args = {
    PKG_RELEASE = "fedora39"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "fedora"
    PKG_DISTRO_ID = "39"
    PKG_DISTRO_SUITE = "39"
    PKG_BASE_IMAGE = "fedora:39"
  }
}

target "_pkg-oraclelinux7" {
  args = {
    PKG_RELEASE = "oraclelinux7"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "oraclelinux"
    PKG_DISTRO_ID = "7"
    PKG_DISTRO_SUITE = "7"
    PKG_BASE_IMAGE = "oraclelinux:7"
  }
}

target "_pkg-oraclelinux8" {
  args = {
    PKG_RELEASE = "oraclelinux8"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "oraclelinux"
    PKG_DISTRO_ID = "8"
    PKG_DISTRO_SUITE = "8"
    PKG_BASE_IMAGE = "oraclelinux:8"
  }
}

target "_pkg-oraclelinux9" {
  args = {
    PKG_RELEASE = "oraclelinux9"
    PKG_TYPE = "rpm"
    PKG_DISTRO = "oraclelinux"
    PKG_DISTRO_ID = "9"
    PKG_DISTRO_SUITE = "9"
    PKG_BASE_IMAGE = "oraclelinux:9"
  }
}

target "_pkg-static" {
  args = {
    PKG_RELEASE = ""
    PKG_TYPE = "static"
    PKG_DISTRO = "static"
    PKG_DISTRO_ID = ""
    PKG_DISTRO_SUITE = ""
    PKG_BASE_IMAGE = "debian:bullseye"
  }
}
