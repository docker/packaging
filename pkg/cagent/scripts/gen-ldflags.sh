#!/bin/sh

# Copyright 2025 Docker Packaging authors
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

# Build info
: "${GO_MODULE:="github.com/docker/cagent"}"
: "${VERSION:="$(git describe --tags --exact-match 2>/dev/null || echo dev)"}"
: "${COMMIT:="$(git rev-parse HEAD 2>/dev/null || echo unknown)"}"
: "${BUILD_TIME:="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"}"

echo -n "-s -w"
echo -n " -X ${GO_MODULE}/cmd/root.Version=${VERSION}"
echo -n " -X ${GO_MODULE}/cmd/root.Commit=${COMMIT}"
echo    " -X ${GO_MODULE}/cmd/root.BuildTime=${BUILD_TIME}"
