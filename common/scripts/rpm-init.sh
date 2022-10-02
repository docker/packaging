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

case "$pkgrelease" in
  centos7)
    [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
    yum install -y rpm-build rpmlint epel-release
    # FIXME: centos 7 has an old git version (1.8)
    yum remove git
    yum install -y centos-release-scl-rh
    yum install -y rh-git227-git
    cat > "/usr/local/bin/git" <<-EOF
#!/bin/sh
source scl_source enable rh-git227
exec git "\$@"
EOF
    chmod +x /usr/local/bin/git
    ;;
  centos8)
    [ -f /etc/yum.repos.d/CentOS-Stream-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Stream-Sources.repo
    [ -f /etc/yum.repos.d/CentOS-Stream-PowerTools.repo ] && sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Stream-PowerTools.repo
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
    dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release epel-next-release
    ;;
  centos9)
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
    dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release epel-next-release
    dnf config-manager --set-enabled crb
    ;;
  oraclelinux7)
    [ -f /etc/yum.repos.d/CentOS-Sources.repo ] && sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo
    yum install -y git rpm-build rpmlint epel-release
    yum-config-manager --enable ol7_addons --enable ol7_optional_latest
    ;;
  oraclelinux8)
    dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release
    dnf config-manager --enable ol8_addons --enable ol8_codeready_builder
    ;;
  oraclelinux9)
    dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release
    dnf config-manager --enable ol9_addons --enable ol9_codeready_builder
    ;;
  fedora*)
    dnf install -y git rpm-build rpmlint dnf-plugins-core
    ;;
esac
