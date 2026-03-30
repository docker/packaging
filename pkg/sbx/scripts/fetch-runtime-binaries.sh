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

# Fetch all linux runtime binaries from a GitHub release.
#
# Usage:
#   GITHUB_TOKEN=ghp_xxx ./fetch-runtime-binaries.sh <repo> <tag> <outdir>
#
# Example:
#   ./fetch-runtime-binaries.sh docker/docker v0.1.0-beta.29 /tmp/runtime-bin

set -eu

REPO="${1:?usage: $0 <repo> <tag> <outdir>}"
TAG="${2:?usage: $0 <repo> <tag> <outdir>}"
OUTDIR="${3:?usage: $0 <repo> <tag> <outdir>}"

mkdir -p "${OUTDIR}"

set -x

gh release download "${TAG}" --repo "${REPO}" --dir "${OUTDIR}" \
  --clobber \
  --pattern "containerd-shim-nerdbox-v1-linux-*" \
  --pattern "mkfs.ext4-linux-*" \
  --pattern "nerdbox-kernel-*" \
  --pattern "nerdbox-initrd-*" \
  --pattern "libkrun-*.so"
