#!/usr/bin/env bash

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

pkgrelease=$1

if [ -z "$pkgrelease" ]; then
  echo "usage: ./verify-rpm-init <pkgrelease>" >&2
  exit 1
fi

set -e

case "$pkgrelease" in
  centos9)
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
    dnf install -y findutils dnf-plugins-core epel-release epel-next-release
    dnf config-manager --set-enabled crb
    ;;
  oraclelinux8)
    dnf install -y findutils dnf-plugins-core oraclelinux-release-el8 oracle-epel-release-el8
    dnf config-manager --enable ol8_addons ol8_codeready_builder
    ;;
  oraclelinux9)
    dnf install -y findutils dnf-plugins-core oraclelinux-release-el9 oracle-epel-release-el9
    dnf config-manager --enable ol9_addons ol9_codeready_builder
    ;;
  fedora*)
    dnf install -y findutils dnf-plugins-core
    ;;
esac
