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

: "${PKG_RELEASE=}"

set -e

if [ -z "$PKG_RELEASE" ]; then
  echo >&2 "error: PKG_RELEASE is required"
  exit 1
fi

if ! command -v xx-info &> /dev/null; then
  echo >&2 "error: xx cross compilation helper is required"
  exit 1
fi

set -x

case "$PKG_RELEASE" in
  ubuntu2004|ubuntu2204)
    if [ "$(dpkg-divert --truename /usr/bin/man)" = "/usr/bin/man.REAL" ]; then
      rm -f /usr/bin/man
      dpkg-divert --quiet --remove --rename /usr/bin/man
    fi
    ;;
esac
