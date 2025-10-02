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
  centos10)
    dnf install -y git rpm-build dnf-plugins-core
    dnf config-manager --set-enabled crb
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
  rockylinux8|almalinux8)
    dnf clean all
    dnf makecache
    dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release
    dnf config-manager --set-enabled powertools
    ;;
  rockylinux*|almalinux*)
    dnf clean all
    dnf makecache
    dnf install -y git rpm-build rpmlint dnf-plugins-core epel-release
    dnf config-manager --set-enabled crb
    ;;
  rhel8|rhel9)
    dnf install -y git rpm-build rpmlint dnf-plugins-core
    ;;
  rhel*)
    dnf install -y git rpm-build dnf-plugins-core
    ;;
esac

case "$pkgrelease" in
  rhel*)
    rm -f /etc/rhsm-host
    if [ -z "$RH_USER" ] || [ -z "$RH_PASS" ]; then
      echo "Either RH_USER or RH_PASS is not set. Running build without subscription."
    else
      subscription-manager register --username="${RH_USER}" --password="${RH_PASS}"
      subscription-manager repos --enable "codeready-builder-for-rhel-$(xx-info os-version | cut -d. -f1)-$(xx-info rhel-arch)-rpms"
      # dnf config-manager --set-enabled codeready-builder-for-rhel-$(xx-info os-version | cut -d. -f1)-$(xx-info rhel-arch)-rpms
    fi
    ;;
esac
