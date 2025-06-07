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
  echo "usage: ./rpm-init <pkgrelease>" >&2
  exit 1
fi

set -e

swcolInstallGit() {
  local version=$1
  yum install -y "rh-git$version-git"
  cat > "/usr/local/bin/git" <<-EOF
#!/bin/sh
source scl_source enable rh-git$version
exec git "\$@"
EOF
  chmod +x /usr/local/bin/git
}

case "$pkgrelease" in
  centos9)
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
    dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release epel-next-release
    dnf config-manager --set-enabled crb
    ;;
  oraclelinux7)
    [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
    yum install -y rpm-build rpmlint oraclelinux-release-el7 oracle-softwarecollection-release-el7 oracle-epel-release-el7
    yum-config-manager --enable ol7_addons ol7_latest ol7_optional_latest ol7_software_collections
    # FIXME: oracle linux 7 has an old git version (1.9) not compatible with
    #  gen-ver script so install it from Software Collection as a workaround.
    #  https://docs.oracle.com/en/operating-systems/oracle-linux/scl-user/ol-scl-relnotes.html#section_e3v_nbl_cr
    yum install -y oracle-softwarecollection-release-el7
    yum-config-manager --enable ol7_software_collections
    swcolInstallGit "29"
    # disable software collections repo when Git installed otherwise wrong deps
    # are picked up by yum-builddep
    yum-config-manager --disable ol7_software_collections
    ;;
  oraclelinux8)
    dnf install -y git rpm-build rpmlint dnf-plugins-core oraclelinux-release-el8 oracle-epel-release-el8
    dnf config-manager --enable ol8_addons ol8_codeready_builder
    ;;
  oraclelinux9)
    dnf install -y git rpm-build rpmlint dnf-plugins-core oraclelinux-release-el9 oracle-epel-release-el9
    dnf config-manager --enable ol9_addons ol9_codeready_builder
    ;;
  fedora*)
    dnf install -y git rpm-build rpmlint dnf-plugins-core
    ;;
esac
