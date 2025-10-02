#!/usr/bin/env bash

# Copyright 2023 Docker Packaging authors
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

arch=$1
specsDir=$2

if [[ -z "$arch" ]] || [[ -z "$specsDir" ]]; then
  echo "usage: ./rpm-builddep <arch> <specs-dir>" >&2
  exit 1
fi

set -e

builddepCmd=""
if command -v dnf &> /dev/null; then
  builddepCmd="setarch $arch dnf --setopt=retries=15 builddep --nobest"
elif command -v yum-builddep &> /dev/null; then
  builddepCmd="yum-builddep --target $arch"
else
  echo "unable to detect package manager" >&2
  exit 1
fi

set -x
$builddepCmd -y "$specsDir"/*.spec
