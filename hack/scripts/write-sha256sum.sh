#!/usr/bin/env bash

# Copyright 2026 Docker Packaging authors
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

set -e

if [ "$#" -ne 1 ]; then
  echo >&2 "usage: write-sha256sum <file>"
  exit 1
fi

file="$1"
case "$file" in
  */*)
    dir="${file%/*}"
    name="${file##*/}"
    ;;
  *)
    dir=.
    name="$file"
    ;;
esac

(
  set -x
  cd "$dir"
  sha256sum "$name" > "${name}.sha256"
)
